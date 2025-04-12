- [x] add "are you sure?" before submitting for connect whastapp, and show phone number in the code page, just ot ensur ebeter experience for user and if entered it in a wrong way.
- [ ] make conflcit resolution work
- [ ] schedule prayer times via mobile app with backend stuff
- [ ] fix rabbitmq and make it robust as a consumer in golang, like the connections (reconnect when it disconnects)
- [ ] google auth in frontend (just open google oauth and send token to backend)

- [ ] reminders on events, like the local events, setup local notifications for events, not sure tbh how to do it, to make sure all events are kept track of, or maybe only our events?
- [ ] make events fetching more robust, and efficient

- [ ] implement refresh and access token to increase security :D, since access token is sent in the headers so you know more time for attacker, very bad :D
- [ ] add some html to the webpage in the downloading of the file, like redirect the user after download somehow so he doesn't panic :D

==== nice to have ====

- [ ] see how to push from the baikal server to update the calendar forcefully in the phone.
- [ ] add "event update in converstaions" if whatsapp messages update themselves, like keep messages til last day of the event, so that we keep context, db might be weird :D
- [ ] onboarding with whatsapp, ask calednar access and add caldav to settings
- [ ] add deep link when the notification of "event added" is sent, so user when he clicks can see the event.
