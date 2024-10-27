CREATE TABLE calendar_accounts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES customer(id) ON DELETE CASCADE,
    provider VARCHAR NOT NULL CHECK (provider IN ('local', 'caldav')),
    
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
    color VARCHAR(7),
    timezone VARCHAR DEFAULT 'UTC',
    sequence INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER update_vcalendar_updated_at
    BEFORE UPDATE ON vcalendar
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

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
    status VARCHAR CHECK (status IN ('CONFIRMED', 'TENTATIVE', 'CANCELLED')),
    classification VARCHAR CHECK (classification IN ('PUBLIC', 'PRIVATE', 'CONFIDENTIAL')),
    transp VARCHAR CHECK (transp IN ('OPAQUE', 'TRANSPARENT')),

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
    status VARCHAR CHECK (status IN ('CONFIRMED', 'TENTATIVE', 'CANCELLED')),
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    CONSTRAINT unique_exception UNIQUE (event_uid, recurrence_id)
);
CREATE TRIGGER update_vevent_exception_updated_at
    BEFORE UPDATE ON vevent_exception
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

CREATE TABLE valarm (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    event_uid VARCHAR NOT NULL REFERENCES vevent(uid) ON DELETE CASCADE,

    -- Alarm properties
    action VARCHAR NOT NULL CHECK (action IN ('AUDIO', 'DISPLAY', 'EMAIL')),
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