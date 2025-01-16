DROP INDEX IF EXISTS idx_calendar_account;
DROP INDEX IF EXISTS idx_event_calendar;
DROP INDEX IF EXISTS idx_event_dtstart;
DROP INDEX IF EXISTS idx_event_dtend;
DROP INDEX IF EXISTS idx_exception_event;
DROP INDEX IF EXISTS idx_alarm_event;

DROP TRIGGER IF EXISTS update_valarm_updated_at ON valarm;
DROP TABLE IF EXISTS valarm;
DROP TYPE alarm_action;

DROP TRIGGER IF EXISTS update_vevent_exception_updated_at ON vevent_exception;
DROP TABLE IF EXISTS vevent_exception;

DROP TRIGGER IF EXISTS update_vevent_updated_at ON vevent;
DROP TABLE IF EXISTS vevent;
DROP TYPE event_status;
DROP TYPE event_classification;
DROP TYPE transparency;

DROP TRIGGER IF EXISTS update_vcalendar_updated_at ON vcalendar;
DROP TABLE IF EXISTS vcalendar;

DROP TRIGGER IF EXISTS update_calendar_accounts_updated_at ON calendar_accounts;
DROP TABLE IF EXISTS calendar_accounts;
DROP TYPE provider_type;