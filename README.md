# Interactive Landing Page

A modern, interactive landing page where users can send and view messages in real-time.

## Features

- **Beautiful Design**: Gradient background with smooth animations
- **Message Board**: Users can post messages with their name
- **Local Storage**: Messages persist between sessions using browser localStorage
- **Responsive**: Works perfectly on desktop and mobile devices
- **Interactive Animations**: Smooth hover effects and transitions
- **Toast Notifications**: User-friendly feedback messages
- **Real-time Display**: Messages appear instantly without page reload

## How to Use

1. Open `index.html` in your web browser
2. Enter your name in the "Your Name" field
3. Type your message in the "Your Message" textarea
4. Click "Send Message" or press Ctrl+Enter to submit
5. Your message will appear in the "Recent Messages" section below

## File Structure

```
.
├── index.html      # Main HTML structure
├── styles.css      # Styling and animations
├── script.js       # Message handling and interactivity
└── README.md       # This file
```

## Technologies Used

- HTML5
- CSS3 (with animations and gradients)
- Vanilla JavaScript (ES6+)
- LocalStorage API

## Browser Compatibility

Works in all modern browsers:
- Chrome
- Firefox
- Safari
- Edge

## Features in Detail

### Message Functionality
- Messages are stored locally in your browser
- Each message shows the author name and time posted
- Messages are displayed in reverse chronological order (newest first)
- Character limits: 50 for names, 500 for messages

### Keyboard Shortcuts
- Press Enter in the name field to jump to the message field
- Press Ctrl+Enter in the message field to send the message

## Customization

You can easily customize the appearance by modifying `styles.css`:
- Change the gradient colors in the `body` background
- Modify the primary color (#667eea) throughout the stylesheet
- Adjust animation timings and effects

## Future Enhancements

Potential features to add:
- Backend integration for persistent storage
- User avatars
- Message reactions (likes, etc.)
- Message editing and deletion
- User authentication
- Real-time updates across multiple users (WebSockets)

## License

Free to use and modify for any purpose.
