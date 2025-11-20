const nodemailer = require('nodemailer');

// Test the nodemailer configuration directly
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'mockupfusion23@gmail.com',
    pass: 'ehhysovktyckpsyl',
  },
});

// Test the transporter
transporter.verify((error, success) => {
  if (error) {
    console.log('❌ Transporter verification failed:', error);
  } else {
    console.log('✅ Transporter is ready to send emails');
    
    // Try sending a test email
    const mailOptions = {
      from: 'PathFit <mockupfusion23@gmail.com>',
      to: 'charlesmiembro24@gmail.com',
      subject: 'Test - 6 Digit Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; border-radius: 10px; text-align: center; color: white;">
            <h1 style="margin: 0; font-size: 28px;">PathFit</h1>
            <p style="margin: 10px 0 0 0; font-size: 16px; opacity: 0.9;">Your Fitness Journey Starts Here</p>
          </div>
          
          <div style="background: #f8f9fa; padding: 30px; border-radius: 10px; margin-top: 20px;">
            <h2 style="color: #333; margin-top: 0;">Email Verification</h2>
            <p style="color: #666; font-size: 16px; line-height: 1.6;">
              Thank you for registering with PathFit! Please use the verification code below to complete your registration.
            </p>
            
            <div style="background: white; border: 2px solid #667eea; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
              <p style="color: #666; margin: 0 0 10px 0; font-size: 14px;">Your verification code:</p>
              <div style="font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 8px; font-family: 'Courier New', monospace;">
                123456
              </div>
            </div>
            
            <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0;">
              <p style="color: #856404; margin: 0; font-size: 14px;">
                <strong>Important:</strong> This code will expire in 10 minutes for security purposes.
              </p>
            </div>
            
            <p style="color: #666; font-size: 14px; margin-top: 20px;">
              If you didn't request this verification, please ignore this email.
            </p>
          </div>
          
          <div style="text-align: center; margin-top: 30px; color: #999; font-size: 12px;">
            <p>© 2024 PathFit. All rights reserved.</p>
          </div>
        </div>
      `
    };

    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.log('❌ Failed to send email:', error);
      } else {
        console.log('✅ Email sent successfully:', info.response);
      }
    });
  }
});