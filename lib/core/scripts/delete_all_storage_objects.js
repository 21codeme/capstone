// Firebase Admin SDK script to delete ALL files in Firebase Storage
// Usage:
//   node lib/core/scripts/delete_all_storage_objects.js [--dry-run] [--prefix <path>] [--bucket <bucket-name>]
// Notes:
//   - This permanently deletes all matching objects from your Storage bucket.
//   - Provide --dry-run to only count and list a sample without deleting.

const admin = require('firebase-admin');
const path = require('path');

let serviceAccount;
try {
  // Service account key expected at project root (same convention as other scripts)
  serviceAccount = require('../../../firebase-admin-key.json');
  console.log('✅ Loaded service account key');
} catch (error) {
  console.error('❌ Failed to load service account key:', error.message);
  console.log('\n⚠️ Place firebase-admin-key.json in the project root.');
  process.exit(1);
}

// Parse CLI args
const args = process.argv.slice(2);
const hasFlag = (flag) => args.includes(flag);
const getArg = (flag) => {
  const idx = args.indexOf(flag);
  if (idx !== -1 && idx + 1 < args.length) return args[idx + 1];
  return undefined;
};

const DRY_RUN = hasFlag('--dry-run');
const PREFIX = getArg('--prefix') || '';
const OVERRIDE_BUCKET = getArg('--bucket');

// Initialize Admin SDK
const projectId = serviceAccount.project_id || serviceAccount.projectId;
// Prefer the same format as Flutter client config, which uses firebasestorage.app
const defaultBucketName = projectId ? `${projectId}.firebasestorage.app` : undefined;
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: OVERRIDE_BUCKET || defaultBucketName
});

const storage = admin.storage();
const bucket = OVERRIDE_BUCKET ? storage.bucket(OVERRIDE_BUCKET) : storage.bucket();

async function listAllFiles(prefix) {
  const options = { prefix, autoPaginate: true }; // autoPaginate to retrieve all pages
  const [files] = await bucket.getFiles(options);
  return files;
}

async function deleteFiles(files) {
  // Delete with modest concurrency to avoid API throttling
  const CONCURRENCY = 20;
  let active = 0;
  let index = 0;
  let deleted = 0;
  let failed = 0;
  const errors = [];

  return new Promise((resolve) => {
    const next = () => {
      if (index >= files.length && active === 0) return resolve({ deleted, failed, errors });
      while (active < CONCURRENCY && index < files.length) {
        const file = files[index++];
        active++;
        file.delete()
          .then(() => { deleted++; })
          .catch((err) => { failed++; errors.push({ name: file.name, error: err.message }); })
          .finally(() => { active--; next(); });
      }
    };
    next();
  });
}

(async function main() {
  try {
    console.log('🔥 Starting Firebase Storage purge');
    if (DRY_RUN) console.log('🔍 Dry-run mode: no deletions will be performed');
    if (PREFIX) console.log(`📂 Restricting to prefix: ${PREFIX}`);
    if (OVERRIDE_BUCKET) console.log(`🪣 Using bucket override: ${OVERRIDE_BUCKET}`);

    // Grace period for abort
    console.log('⚠️ Press Ctrl+C within 5 seconds to abort');
    await new Promise((r) => setTimeout(r, 5000));

    console.log('🔎 Listing files...');
    const files = await listAllFiles(PREFIX);
    console.log(`📊 Found ${files.length} file(s) in bucket ${bucket.name}${PREFIX ? ` with prefix '${PREFIX}'` : ''}`);

    if (files.length === 0) {
      console.log('ℹ️ No files to process. Exiting.');
      process.exit(0);
    }

    // Show sample of first few files
    console.log('🧾 Sample files:');
    files.slice(0, Math.min(10, files.length)).forEach((f, i) => console.log(`  ${i + 1}. ${f.name}`));

    if (DRY_RUN) {
      console.log('\n✅ Dry-run complete. No files were deleted.');
      process.exit(0);
    }

    console.log('🗑️ Deleting files...');
    const { deleted, failed, errors } = await deleteFiles(files);
    console.log(`\n✅ Deleted: ${deleted}`);
    if (failed > 0) {
      console.log(`⚠️ Failed: ${failed}`);
      errors.slice(0, 10).forEach((e, i) => console.log(`  ${i + 1}. ${e.name}: ${e.error}`));
    }
    console.log('\n🎉 Storage purge completed.');
  } catch (error) {
    console.error('❌ Fatal error during purge:', error);
    process.exit(1);
  }
})();