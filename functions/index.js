const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const cors = require('cors')({origin: true});

admin.initializeApp();

exports.sendVolunteerHoursEmail = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    const {recipient, subject, body, attachment} = req.body;

    // Validate input
    if (!recipient || !subject || !body || !attachment) {
      return res.status(400).json({error: 'Missing required fields'});
    }

    // Configure the email transport using the default SMTP transport
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: 'noreply.childrensmusicbrigade@gmail.com',
        pass: 'rfws gqcj rduc vxyy',
      },
    });

    // Set up the email options
    const mailOptions = {
      from: 'noreply.childrensmusicbrigade@gmail.com',
      to: recipient,
      subject: subject,
      text: body,
      attachments: [
        {
          filename: 'volunteer_hours.pdf',
          content: attachment,
          encoding: 'base64',
        },
      ],
    };

    // Send the email
    try {
      await transporter.sendMail(mailOptions);
      res.status(200).json({success: true});
    } catch (error) {
      res.status(500).json({error: error.toString()});
    }
  });
});
