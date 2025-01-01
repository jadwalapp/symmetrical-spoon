CREATE TYPE provider_type AS ENUM ('local', 'caldav');
CREATE TABLE calendar_accounts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customer(id) ON DELETE CASCADE,
    provider provider_type NOT NULL,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_calendar_accounts_updated_at
    BEFORE UPDATE ON calendar_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();


CREATE TABLE vcalendar (
    uid VARCHAR PRIMARY KEY,
    account_id UUID NOT NULL REFERENCES calendar_accounts(id) ON DELETE CASCADE,

    -- Required iCal fields
    prodid VARCHAR NOT NULL,
    version VARCHAR NOT NULL DEFAULT '2.0',
    calscale VARCHAR DEFAULT 'GREGORIAN',
    
    -- Calendar properties
    display_name VARCHAR NOT NULL,
    description TEXT,
    color VARCHAR(7) NOT NULL CHECK (color ~ '^#[0-9a-fA-F]{6}$'),
    timezone VARCHAR DEFAULT 'UTC',
    sequence INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_vcalendar_updated_at
    BEFORE UPDATE ON vcalendar
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();


CREATE TYPE event_status AS ENUM ('CONFIRMED', 'TENTATIVE', 'CANCELLED');
CREATE TYPE event_classification AS ENUM ('PUBLIC', 'PRIVATE', 'CONFIDENTIAL');
CREATE TYPE transparency AS ENUM ('OPAQUE', 'TRANSPARENT');
CREATE TABLE vevent (
    uid VARCHAR PRIMARY KEY,
    calendar_uid VARCHAR NOT NULL REFERENCES vcalendar(uid) ON DELETE CASCADE,

    -- Timing fields
    dtstamp TIMESTAMPTZ NOT NULL,
    dtstart TIMESTAMPTZ NOT NULL,
    dtend TIMESTAMPTZ,
    duration VARCHAR,

    -- Event details
    summary VARCHAR NOT NULL,
    description TEXT,
    location VARCHAR,

    -- Event properties
    status event_status,
    classification event_classification,
    transp transparency,

    -- Recurrence fields
    rrule VARCHAR,
    rdate JSONB,
    exdate JSONB,
    sequence INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_vevent_updated_at
    BEFORE UPDATE ON vevent
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();


CREATE TABLE vevent_exception (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    event_uid VARCHAR NOT NULL REFERENCES vevent(uid) ON DELETE CASCADE,
    recurrence_id TIMESTAMPTZ NOT NULL,

    -- Overridable fields
    summary VARCHAR,
    description TEXT,
    location VARCHAR,
    dtstart TIMESTAMPTZ,
    dtend TIMESTAMPTZ,
    status event_status,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    CONSTRAINT unique_exception UNIQUE (event_uid, recurrence_id)
);
CREATE TRIGGER update_vevent_exception_updated_at
    BEFORE UPDATE ON vevent_exception
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();


CREATE TYPE alarm_action AS ENUM ('AUDIO', 'DISPLAY', 'EMAIL');
CREATE TABLE valarm (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    event_uid VARCHAR NOT NULL REFERENCES vevent(uid) ON DELETE CASCADE,

    -- Alarm properties
    action alarm_action NOT NULL,
    trigger VARCHAR NOT NULL,
    description TEXT,
    summary VARCHAR,
    duration VARCHAR,
    repeat INTEGER,
    attendees JSONB,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_valarm_updated_at
    BEFORE UPDATE ON valarm
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();


CREATE INDEX idx_calendar_account ON vcalendar(account_id);
CREATE INDEX idx_event_calendar ON vevent(calendar_uid);
CREATE INDEX idx_event_dtstart ON vevent(dtstart);
CREATE INDEX idx_event_dtend ON vevent(dtend);
CREATE INDEX idx_exception_event ON vevent_exception(event_uid);
CREATE INDEX idx_alarm_event ON valarm(event_uid);
