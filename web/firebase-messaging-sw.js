importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyDpWnU5o9KoM3vBLh9xSbMYfQfNJbQyvMk",
    authDomain: "flatsync-1db9f.firebaseapp.com",
    projectId: "flatsync-1db9f",
    storageBucket: "flatsync-1db9f.appspot.com",
    messagingSenderId: "104878832188",
    appId: "1:104878832188:web:4a18acbe5bec41ba9be139"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log("[firebase-messaging-sw.js] Received background message ", payload);

    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: "/icons/icon-192x192.png"
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
