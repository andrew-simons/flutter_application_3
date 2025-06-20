const nodemailer = require('nodemailer');

// Create a transporter object using SMTP transport
let transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'noreply.childrensmusicbrigade@gmail.com',
        pass: 'rfws gqcj rduc vxyy' // Use the password for your Gmail account
    }
});

// Define mail options
let mailOptions = {
    from: 'childrensmusicbrigade@gmail.com',
    to: 'ansimonss@gmail.com',
    subject: 'Test Email',
    text: 'This is a test email sent from Node.js using Nodemailer!'
};

// Send email
transporter.sendMail(mailOptions, function(error, info) {
    if (error) {
        console.log('Error: ' + error);
    } else {
        console.log('Email sent: ' + info.response);
    }
});
