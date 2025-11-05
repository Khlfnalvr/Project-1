// Initialize messages array from localStorage or empty array
let messages = JSON.parse(localStorage.getItem('messages')) || [];

// DOM elements
const nameInput = document.getElementById('nameInput');
const messageInput = document.getElementById('messageInput');
const sendBtn = document.getElementById('sendBtn');
const messagesContainer = document.getElementById('messagesContainer');
const toast = document.getElementById('toast');

// Initialize the page
document.addEventListener('DOMContentLoaded', () => {
    displayMessages();

    // Add event listeners
    sendBtn.addEventListener('click', handleSendMessage);

    // Allow Enter key to send message (Ctrl+Enter for textarea)
    messageInput.addEventListener('keydown', (e) => {
        if (e.ctrlKey && e.key === 'Enter') {
            handleSendMessage();
        }
    });

    nameInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            messageInput.focus();
        }
    });
});

// Handle sending a message
function handleSendMessage() {
    const name = nameInput.value.trim();
    const messageText = messageInput.value.trim();

    // Validation
    if (!name) {
        showToast('Please enter your name', 'error');
        nameInput.focus();
        return;
    }

    if (!messageText) {
        showToast('Please enter a message', 'error');
        messageInput.focus();
        return;
    }

    // Create message object
    const message = {
        id: Date.now(),
        name: name,
        text: messageText,
        timestamp: new Date().toISOString()
    };

    // Add to messages array
    messages.unshift(message); // Add to beginning of array

    // Save to localStorage
    saveMessages();

    // Display messages
    displayMessages();

    // Clear inputs
    messageInput.value = '';
    messageInput.focus();

    // Show success message
    showToast('Message sent successfully!', 'success');

    // Add a nice animation to the send button
    sendBtn.style.transform = 'scale(0.95)';
    setTimeout(() => {
        sendBtn.style.transform = 'scale(1)';
    }, 100);
}

// Display all messages
function displayMessages() {
    if (messages.length === 0) {
        messagesContainer.innerHTML = `
            <div class="empty-state">
                <p>No messages yet. Be the first to share your thoughts!</p>
            </div>
        `;
        return;
    }

    messagesContainer.innerHTML = messages.map(message => createMessageCard(message)).join('');

    // Add delete functionality
    document.querySelectorAll('.delete-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const messageId = parseInt(e.target.dataset.id);
            deleteMessage(messageId);
        });
    });
}

// Create a message card HTML
function createMessageCard(message) {
    const timeAgo = getTimeAgo(new Date(message.timestamp));

    return `
        <div class="message-card">
            <div class="message-header">
                <span class="message-author">${escapeHtml(message.name)}</span>
                <span class="message-time">${timeAgo}</span>
            </div>
            <div class="message-text">${escapeHtml(message.text)}</div>
        </div>
    `;
}

// Delete a message
function deleteMessage(id) {
    messages = messages.filter(msg => msg.id !== id);
    saveMessages();
    displayMessages();
    showToast('Message deleted', 'success');
}

// Save messages to localStorage
function saveMessages() {
    localStorage.setItem('messages', JSON.stringify(messages));
}

// Show toast notification
function showToast(message, type = 'success') {
    toast.textContent = message;
    toast.className = `toast show ${type}`;

    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// Calculate time ago
function getTimeAgo(date) {
    const seconds = Math.floor((new Date() - date) / 1000);

    if (seconds < 60) return 'Just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)} minutes ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)} hours ago`;
    if (seconds < 604800) return `${Math.floor(seconds / 86400)} days ago`;

    return date.toLocaleDateString();
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Add some interactive effects
document.addEventListener('mousemove', (e) => {
    const hero = document.querySelector('.hero');
    if (hero) {
        const x = e.clientX / window.innerWidth;
        const y = e.clientY / window.innerHeight;

        hero.style.backgroundPosition = `${x * 100}% ${y * 100}%`;
    }
});

// Add click effect to message cards
document.addEventListener('click', (e) => {
    if (e.target.classList.contains('message-card')) {
        e.target.style.transform = 'scale(0.98)';
        setTimeout(() => {
            e.target.style.transform = 'scale(1)';
        }, 100);
    }
});
