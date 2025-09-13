-- =====================================================
-- Virtual Event Booking System Database Schema
-- =====================================================
-- This schema supports AI-driven virtual event management
-- with features for booking, personalization, and analytics
-- =====================================================

-- =====================================================
-- 1. CORE USER MANAGEMENT
-- =====================================================

-- User roles definition
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Main users table with enhanced profile information
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    profile_picture_url TEXT,
    timezone VARCHAR(50) DEFAULT 'UTC',
    language_preference VARCHAR(10) DEFAULT 'en',
    email_notifications_enabled BOOLEAN DEFAULT true,
    push_notifications_enabled BOOLEAN DEFAULT true,
    account_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (account_status IN ('ACTIVE', 'SUSPENDED', 'INACTIVE')),
    last_login_at TIMESTAMP,
    email_verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP -- Soft delete
);

-- User role assignments (many-to-many)
CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by INTEGER REFERENCES users(id),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(user_id, role_id)
);

-- Organizations/Companies hosting events
CREATE TABLE organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    website_url TEXT,
    logo_url TEXT,
    industry VARCHAR(100),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Organization membership
CREATE TABLE organization_members (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_in_org VARCHAR(50) DEFAULT 'MEMBER',
    permissions TEXT[], -- Array of permission strings
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(organization_id, user_id)
);

-- =====================================================
-- 2. EVENT MANAGEMENT SYSTEM
-- =====================================================

-- Event categories for classification
CREATE TABLE event_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon_url TEXT,
    color_code VARCHAR(7), -- Hex color code
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Main events table
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    short_description TEXT,
    banner_image_url TEXT,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('CONFERENCE', 'WORKSHOP', 'SEMINAR', 'CONCERT', 'MEETING', 'TRAINING', 'WEBINAR')),
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PUBLISHED', 'LIVE', 'COMPLETED', 'CANCELLED')),
    is_public BOOLEAN DEFAULT true,
    is_free BOOLEAN DEFAULT true,
    base_price DECIMAL(10,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Organizer information
    organization_id INTEGER REFERENCES organizations(id),
    primary_organizer_id INTEGER NOT NULL REFERENCES users(id),
    
    -- Event scheduling
    start_datetime TIMESTAMP NOT NULL,
    end_datetime TIMESTAMP NOT NULL,
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
    registration_start_datetime TIMESTAMP,
    registration_end_datetime TIMESTAMP,
    
    -- Capacity management
    max_attendees INTEGER,
    current_registrations INTEGER DEFAULT 0,
    waitlist_enabled BOOLEAN DEFAULT false,
    max_waitlist INTEGER,
    current_waitlist INTEGER DEFAULT 0,
    
    -- Event categorization
    category_id INTEGER REFERENCES event_categories(id),
    tags TEXT[], -- Array of tag strings
    
    -- Technical requirements
    platform VARCHAR(50), -- ZOOM, TEAMS, CUSTOM, METAVERSE
    meeting_url TEXT,
    meeting_id VARCHAR(100),
    meeting_password VARCHAR(100),
    
    -- SEO and metadata
    slug VARCHAR(255) UNIQUE,
    meta_title VARCHAR(255),
    meta_description TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Event sessions (for multi-session events)
CREATE TABLE event_sessions (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    session_type VARCHAR(50) CHECK (session_type IN ('KEYNOTE', 'PRESENTATION', 'WORKSHOP', 'PANEL', 'NETWORKING', 'BREAK', 'Q_AND_A')),
    
    -- Session scheduling
    start_datetime TIMESTAMP NOT NULL,
    end_datetime TIMESTAMP NOT NULL,
    
    -- Session capacity (can be different from main event)
    max_attendees INTEGER,
    current_registrations INTEGER DEFAULT 0,
    
    -- Session location (virtual or physical)
    location_type VARCHAR(20) DEFAULT 'VIRTUAL' CHECK (location_type IN ('VIRTUAL', 'PHYSICAL', 'HYBRID')),
    virtual_room_url TEXT,
    virtual_room_id VARCHAR(100),
    physical_location TEXT,
    
    -- Session ordering
    display_order INTEGER DEFAULT 0,
    is_mandatory BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Event speakers/presenters
CREATE TABLE speakers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id), -- NULL if external speaker
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    bio TEXT,
    title VARCHAR(255),
    company VARCHAR(255),
    profile_image_url TEXT,
    linkedin_url TEXT,
    twitter_handle VARCHAR(50),
    website_url TEXT,
    expertise_areas TEXT[], -- Array of expertise strings
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Speaker assignments to events/sessions
CREATE TABLE event_speakers (
    id SERIAL PRIMARY KEY,
    event_id INTEGER REFERENCES events(id) ON DELETE CASCADE,
    session_id INTEGER REFERENCES event_sessions(id) ON DELETE CASCADE,
    speaker_id INTEGER NOT NULL REFERENCES speakers(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'SPEAKER' CHECK (role IN ('SPEAKER', 'MODERATOR', 'PANELIST', 'HOST')),
    speaking_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. BOOKING AND REGISTRATION SYSTEM
-- =====================================================

-- Main booking/registration table
CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Booking details
    booking_reference VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'CONFIRMED' CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'WAITLIST', 'NO_SHOW', 'ATTENDED')),
    booking_type VARCHAR(20) DEFAULT 'REGULAR' CHECK (booking_type IN ('REGULAR', 'VIP', 'PRESS', 'SPEAKER', 'SPONSOR')),
    
    -- Payment information
    total_amount DECIMAL(10,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_status VARCHAR(20) DEFAULT 'FREE' CHECK (payment_status IN ('FREE', 'PENDING', 'PAID', 'REFUNDED', 'FAILED')),
    payment_method VARCHAR(50),
    payment_reference VARCHAR(100),
    payment_date TIMESTAMP,
    
    -- Registration details
    registration_source VARCHAR(50), -- WEB, MOBILE, API, IMPORT
    special_requirements TEXT,
    dietary_restrictions TEXT,
    accessibility_needs TEXT,
    
    -- Attendance tracking
    check_in_time TIMESTAMP,
    check_out_time TIMESTAMP,
    attendance_duration_minutes INTEGER,
    
    -- Timestamps
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cancelled_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(event_id, user_id)
);

-- Session-specific bookings (for events with multiple sessions)
CREATE TABLE session_bookings (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    session_id INTEGER NOT NULL REFERENCES event_sessions(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'REGISTERED' CHECK (status IN ('REGISTERED', 'ATTENDED', 'MISSED', 'CANCELLED')),
    
    check_in_time TIMESTAMP,
    check_out_time TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(booking_id, session_id)
);

-- =====================================================
-- 4. AI AND PERSONALIZATION SYSTEM
-- =====================================================

-- User preferences for AI personalization
CREATE TABLE user_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Interest categories
    preferred_categories INTEGER[] REFERENCES event_categories(id),
    preferred_event_types TEXT[],
    preferred_duration_hours INTEGER,
    preferred_time_slots TEXT[], -- MORNING, AFTERNOON, EVENING, NIGHT
    preferred_days_of_week INTEGER[], -- 1-7, Monday = 1
    
    -- Learning preferences
    learning_style VARCHAR(20) CHECK (learning_style IN ('VISUAL', 'AUDITORY', 'KINESTHETIC', 'MIXED')),
    experience_level VARCHAR(20) CHECK (experience_level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')),
    
    -- AI interaction preferences
    ai_chat_enabled BOOLEAN DEFAULT true,
    ai_recommendations_enabled BOOLEAN DEFAULT true,
    ai_schedule_optimization BOOLEAN DEFAULT true,
    
    -- Privacy settings
    data_sharing_consent BOOLEAN DEFAULT false,
    analytics_consent BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id)
);

-- AI chatbot interactions
CREATE TABLE ai_chat_interactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(100) NOT NULL, -- Chat session identifier
    
    -- Message details
    message_type VARCHAR(20) CHECK (message_type IN ('USER', 'AI', 'SYSTEM')),
    message_content TEXT NOT NULL,
    intent VARCHAR(100), -- Detected user intent
    confidence_score DECIMAL(3,2), -- AI confidence in intent detection
    
    -- Context
    event_id INTEGER REFERENCES events(id),
    booking_id INTEGER REFERENCES bookings(id),
    
    -- NLP analysis
    sentiment_score DECIMAL(3,2), -- -1.0 to 1.0
    entities_extracted JSONB, -- Extracted entities from the message
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI predictions for event management
CREATE TABLE ai_predictions (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    prediction_type VARCHAR(50) NOT NULL CHECK (prediction_type IN ('ATTENDANCE', 'ENGAGEMENT', 'CAPACITY', 'CANCELLATION', 'REVENUE')),
    
    -- Prediction details
    model_version VARCHAR(20),
    predicted_value DECIMAL(12,2),
    confidence_interval_lower DECIMAL(12,2),
    confidence_interval_upper DECIMAL(12,2),
    confidence_percentage DECIMAL(5,2),
    
    -- Model inputs (for reproducibility)
    input_features JSONB,
    
    -- Validation
    actual_value DECIMAL(12,2), -- Filled after event completion
    prediction_accuracy DECIMAL(5,2), -- Calculated accuracy percentage
    
    prediction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_date TIMESTAMP, -- When the prediction is for
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Personalized event recommendations
CREATE TABLE ai_recommendations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    
    -- Recommendation scoring
    relevance_score DECIMAL(3,2) NOT NULL, -- 0.0 to 1.0
    recommendation_reason TEXT,
    algorithm_version VARCHAR(20),
    
    -- User interaction
    shown_to_user BOOLEAN DEFAULT false,
    user_clicked BOOLEAN DEFAULT false,
    user_registered BOOLEAN DEFAULT false,
    user_feedback_rating INTEGER CHECK (user_feedback_rating >= 1 AND user_feedback_rating <= 5),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    
    UNIQUE(user_id, event_id)
);

-- =====================================================
-- 5. METAVERSE AND VIRTUAL SPACES
-- =====================================================

-- Virtual spaces/metaverse environments
CREATE TABLE metaverse_spaces (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    space_type VARCHAR(50) CHECK (space_type IN ('AUDITORIUM', 'MEETING_ROOM', 'EXHIBITION_HALL', 'NETWORKING_AREA', 'CUSTOM')),
    
    -- Capacity and technical specs
    max_avatars INTEGER,
    supported_platforms TEXT[], -- WEBXR, UNITY, UNREAL, etc.
    
    -- 3D Environment details
    environment_url TEXT, -- URL to 3D environment assets
    default_spawn_coordinates JSONB, -- {x, y, z} coordinates
    environment_settings JSONB, -- Lighting, physics, etc.
    
    -- Access control
    access_level VARCHAR(20) DEFAULT 'PUBLIC' CHECK (access_level IN ('PUBLIC', 'PRIVATE', 'RESTRICTED')),
    required_permissions TEXT[],
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Link events to metaverse spaces
CREATE TABLE event_metaverse_spaces (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    session_id INTEGER REFERENCES event_sessions(id) ON DELETE CASCADE,
    metaverse_space_id INTEGER NOT NULL REFERENCES metaverse_spaces(id) ON DELETE CASCADE,
    
    -- Space configuration for this event
    custom_settings JSONB, -- Event-specific environment settings
    is_primary_space BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(event_id, session_id, metaverse_space_id)
);

-- User avatar and metaverse profiles
CREATE TABLE user_metaverse_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Avatar configuration
    avatar_model_url TEXT,
    avatar_customization JSONB, -- Avatar appearance settings
    preferred_username VARCHAR(100),
    
    -- Metaverse preferences
    preferred_interaction_mode VARCHAR(20) CHECK (preferred_interaction_mode IN ('VR', 'AR', 'DESKTOP', 'MOBILE')),
    voice_chat_enabled BOOLEAN DEFAULT true,
    spatial_audio_enabled BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id)
);

-- =====================================================
-- 6. FEEDBACK AND ANALYTICS SYSTEM
-- =====================================================

-- Event feedback collection
CREATE TABLE event_feedback (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Allow anonymous feedback
    booking_id INTEGER REFERENCES bookings(id) ON DELETE SET NULL,
    
    -- Overall ratings (1-5 scale)
    overall_rating INTEGER CHECK (overall_rating >= 1 AND overall_rating <= 5),
    content_quality_rating INTEGER CHECK (content_quality_rating >= 1 AND content_quality_rating <= 5),
    speaker_rating INTEGER CHECK (speaker_rating >= 1 AND speaker_rating <= 5),
    technical_quality_rating INTEGER CHECK (technical_quality_rating >= 1 AND technical_quality_rating <= 5),
    organization_rating INTEGER CHECK (organization_rating >= 1 AND organization_rating <= 5),
    
    -- Detailed feedback
    feedback_text TEXT,
    suggestions TEXT,
    would_recommend BOOLEAN,
    likelihood_to_attend_future INTEGER CHECK (likelihood_to_attend_future >= 1 AND likelihood_to_attend_future <= 10),
    
    -- AI Analysis
    sentiment_score DECIMAL(3,2), -- -1.0 (negative) to 1.0 (positive)
    sentiment_confidence DECIMAL(3,2),
    key_topics JSONB, -- Extracted topics from text analysis
    emotion_analysis JSONB, -- Joy, anger, sadness, etc.
    
    -- Feedback context
    submitted_via VARCHAR(20) DEFAULT 'WEB', -- WEB, MOBILE, EMAIL, API
    is_anonymous BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Session-specific feedback
CREATE TABLE session_feedback (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL REFERENCES event_sessions(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    session_booking_id INTEGER REFERENCES session_bookings(id) ON DELETE SET NULL,
    
    -- Session ratings
    content_rating INTEGER CHECK (content_rating >= 1 AND content_rating <= 5),
    speaker_rating INTEGER CHECK (speaker_rating >= 1 AND speaker_rating <= 5),
    interaction_level_rating INTEGER CHECK (interaction_level_rating >= 1 AND interaction_level_rating <= 5),
    
    feedback_text TEXT,
    most_valuable_aspect TEXT,
    improvement_suggestions TEXT,
    
    -- AI Analysis
    sentiment_score DECIMAL(3,2),
    key_themes JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Speaker-specific feedback
CREATE TABLE speaker_feedback (
    id SERIAL PRIMARY KEY,
    speaker_id INTEGER NOT NULL REFERENCES speakers(id) ON DELETE CASCADE,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    
    -- Speaker evaluation
    presentation_skills_rating INTEGER CHECK (presentation_skills_rating >= 1 AND presentation_skills_rating <= 5),
    knowledge_depth_rating INTEGER CHECK (knowledge_depth_rating >= 1 AND knowledge_depth_rating <= 5),
    engagement_rating INTEGER CHECK (engagement_rating >= 1 AND engagement_rating <= 5),
    clarity_rating INTEGER CHECK (clarity_rating >= 1 AND clarity_rating <= 5),
    
    feedback_comments TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Event analytics and metrics
CREATE TABLE event_analytics (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    analytics_date DATE NOT NULL,
    
    -- Registration metrics
    total_registrations INTEGER DEFAULT 0,
    new_registrations_today INTEGER DEFAULT 0,
    cancellations_today INTEGER DEFAULT 0,
    waitlist_additions INTEGER DEFAULT 0,
    
    -- Attendance metrics
    total_attendees INTEGER DEFAULT 0,
    peak_concurrent_attendees INTEGER DEFAULT 0,
    average_session_duration_minutes INTEGER DEFAULT 0,
    total_engagement_time_hours DECIMAL(10,2) DEFAULT 0,
    
    -- Technical metrics
    average_connection_quality DECIMAL(3,2), -- 1.0 (poor) to 5.0 (excellent)
    technical_issues_count INTEGER DEFAULT 0,
    support_tickets_count INTEGER DEFAULT 0,
    
    -- Interaction metrics
    chat_messages_count INTEGER DEFAULT 0,
    questions_asked INTEGER DEFAULT 0,
    polls_participated INTEGER DEFAULT 0,
    
    -- AI metrics
    ai_recommendations_shown INTEGER DEFAULT 0,
    ai_recommendations_clicked INTEGER DEFAULT 0,
    chatbot_interactions INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(event_id, analytics_date)
);

-- User engagement tracking
CREATE TABLE user_engagement_metrics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    
    -- Engagement scores (0.0 to 1.0)
    overall_engagement_score DECIMAL(3,2) DEFAULT 0.00,
    attendance_score DECIMAL(3,2) DEFAULT 0.00, -- Based on attendance duration
    interaction_score DECIMAL(3,2) DEFAULT 0.00, -- Based on chat, polls, Q&A
    content_consumption_score DECIMAL(3,2) DEFAULT 0.00,
    
    -- Detailed metrics
    total_time_spent_minutes INTEGER DEFAULT 0,
    sessions_attended INTEGER DEFAULT 0,
    chat_messages_sent INTEGER DEFAULT 0,
    polls_participated INTEGER DEFAULT 0,
    questions_asked INTEGER DEFAULT 0,
    resources_downloaded INTEGER DEFAULT 0,
    
    -- Behavior patterns
    preferred_session_types TEXT[],
    peak_activity_hours INTEGER[], -- Hours of day when most active
    
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, event_id)
);

-- =====================================================
-- 7. CALENDAR AND EXTERNAL INTEGRATIONS
-- =====================================================

-- Calendar integration settings per user
CREATE TABLE calendar_integrations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Integration details
    provider VARCHAR(50) NOT NULL CHECK (provider IN ('GOOGLE', 'OUTLOOK', 'APPLE', 'CALDAV', 'OUTLOOK365')),
    provider_user_id VARCHAR(255), -- External calendar user ID
    access_token TEXT, -- Encrypted access token
    refresh_token TEXT, -- Encrypted refresh token
    token_expires_at TIMESTAMP,
    
    -- Integration settings
    is_active BOOLEAN DEFAULT true,
    sync_direction VARCHAR(20) DEFAULT 'BOTH' CHECK (sync_direction IN ('TO_EXTERNAL', 'FROM_EXTERNAL', 'BOTH', 'NONE')),
    auto_add_events BOOLEAN DEFAULT true,
    send_reminders BOOLEAN DEFAULT true,
    calendar_name VARCHAR(255), -- Name of the calendar to sync with
    
    -- Sync status
    last_sync_at TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (sync_status IN ('ACTIVE', 'ERROR', 'PAUSED', 'EXPIRED')),
    last_error_message TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, provider)
);

-- Calendar sync logs
CREATE TABLE calendar_sync_logs (
    id SERIAL PRIMARY KEY,
    calendar_integration_id INTEGER NOT NULL REFERENCES calendar_integrations(id) ON DELETE CASCADE,
    event_id INTEGER REFERENCES events(id) ON DELETE SET NULL,
    
    -- Sync operation details
    operation_type VARCHAR(20) CHECK (operation_type IN ('CREATE', 'UPDATE', 'DELETE', 'SYNC')),
    sync_direction VARCHAR(20) CHECK (sync_direction IN ('TO_EXTERNAL', 'FROM_EXTERNAL')),
    external_event_id VARCHAR(255),
    
    -- Operation result
    status VARCHAR(20) CHECK (status IN ('SUCCESS', 'ERROR', 'PARTIAL')),
    error_message TEXT,
    
    -- Sync metadata
    synced_fields JSONB, -- Fields that were synchronized
    conflict_resolution VARCHAR(50), -- How conflicts were resolved
    
    sync_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 8. SYSTEM NOTIFICATIONS AND COMMUNICATIONS
-- =====================================================

-- Notification templates
CREATE TABLE notification_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL UNIQUE,
    template_type VARCHAR(50) NOT NULL CHECK (template_type IN ('EMAIL', 'PUSH', 'SMS', 'IN_APP')),
    
    -- Template content
    subject_template TEXT,
    body_template TEXT NOT NULL,
    html_body_template TEXT,
    
    -- Template metadata
    supported_variables JSONB, -- List of supported template variables
    category VARCHAR(50), -- BOOKING, REMINDER, FEEDBACK, MARKETING
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User notifications
CREATE TABLE user_notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Notification content
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    priority VARCHAR(20) DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    
    -- Related entities
    event_id INTEGER REFERENCES events(id) ON DELETE SET NULL,
    booking_id INTEGER REFERENCES bookings(id) ON DELETE SET NULL,
    
    -- Delivery status
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP,
    
    -- Delivery channels
    delivered_via TEXT[], -- Array of delivery methods used
    email_sent BOOLEAN DEFAULT false,
    email_opened BOOLEAN DEFAULT false,
    push_sent BOOLEAN DEFAULT false,
    push_opened BOOLEAN DEFAULT false,
    
    -- Scheduling
    scheduled_for TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP,
    expires_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 9. SYSTEM AUDIT AND MONITORING
-- =====================================================

-- Audit trail for important system changes
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    
    -- Entity information
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER NOT NULL,
    operation_type VARCHAR(20) NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE', 'SOFT_DELETE')),
    
    -- User context
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    user_ip_address INET,
    user_agent TEXT,
    
    -- Change details
    old_values JSONB, -- Previous values for updates
    new_values JSONB, -- New values for inserts/updates
    changed_fields TEXT[], -- List of fields that changed
    
    -- Metadata
    reason VARCHAR(255), -- Reason for the change
    session_id VARCHAR(100),
    request_id VARCHAR(100),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- System performance metrics
CREATE TABLE system_metrics (
    id SERIAL PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_type VARCHAR(50) CHECK (metric_type IN ('COUNTER', 'GAUGE', 'HISTOGRAM', 'TIMER')),
    
    -- Metric values
    metric_value DECIMAL(15,6) NOT NULL,
    unit VARCHAR(20),
    
    -- Dimensions/tags
    dimensions JSONB, -- Key-value pairs for metric dimensions
    
    -- Timing
    measurement_timestamp TIMESTAMP NOT NULL,
    
    -- Metadata
    source VARCHAR(50), -- APPLICATION, DATABASE, EXTERNAL_API
    environment VARCHAR(20) DEFAULT 'PRODUCTION',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 10. PERFORMANCE OPTIMIZATION INDEXES
-- =====================================================

-- User-related indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status_active ON users(account_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created_at ON users(created_at);

-- Event-related indexes
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_start_datetime ON events(start_datetime);
CREATE INDEX idx_events_category ON events(category_id);
CREATE INDEX idx_events_organization ON events(organization_id);
CREATE INDEX idx_events_slug ON events(slug);
CREATE INDEX idx_events_public_active ON events(is_public, status) WHERE deleted_at IS NULL;

-- Booking-related indexes
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_event_id ON bookings(event_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_registered_at ON bookings(registered_at);
CREATE INDEX idx_bookings_reference ON bookings(booking_reference);

-- AI and personalization indexes
CREATE INDEX idx_ai_interactions_user_session ON ai_chat_interactions(user_id, session_id);
CREATE INDEX idx_ai_interactions_created_at ON ai_chat_interactions(created_at);
CREATE INDEX idx_ai_predictions_event_type ON ai_predictions(event_id, prediction_type);
CREATE INDEX idx_ai_recommendations_user_score ON ai_recommendations(user_id, relevance_score DESC);

-- Analytics indexes
CREATE INDEX idx_event_analytics_event_date ON event_analytics(event_id, analytics_date);
CREATE INDEX idx_user_engagement_event ON user_engagement_metrics(event_id, overall_engagement_score DESC);

-- Notification indexes
CREATE INDEX idx_user_notifications_user_unread ON user_notifications(user_id, is_read, created_at DESC);
CREATE INDEX idx_user_notifications_scheduled ON user_notifications(scheduled_for) WHERE delivered_at IS NULL;

-- Audit indexes
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_user_timestamp ON audit_logs(user_id, created_at);

-- Calendar integration indexes
CREATE INDEX idx_calendar_integrations_user_active ON calendar_integrations(user_id, is_active);
CREATE INDEX idx_calendar_sync_logs_timestamp ON calendar_sync_logs(sync_timestamp);

-- =====================================================
-- 11. INITIAL DATA SETUP
-- =====================================================

-- Insert default roles
INSERT INTO roles (role_name, description) VALUES 
('ADMIN', 'System administrator with full access'),
('ORGANIZER', 'Event organizer who can create and manage events'),
('ATTENDEE', 'Regular user who can register for and attend events'),
('SPEAKER', 'Event speaker or presenter'),
('MODERATOR', 'Event moderator with limited management capabilities');

-- Insert default event categories
INSERT INTO event_categories (name, description, color_code) VALUES 
('Technology', 'Tech conferences, workshops, and seminars', '#2563EB'),
('Business', 'Business meetings, corporate events, and networking', '#059669'),
('Education', 'Educational workshops, training sessions, and courses', '#DC2626'),
('Entertainment', 'Concerts, shows, and entertainment events', '#7C3AED'),
('Health & Wellness', 'Health seminars, fitness events, and wellness workshops', '#EA580C'),
('Arts & Culture', 'Art exhibitions, cultural events, and creative workshops', '#DB2777'),
('Science', 'Scientific conferences, research presentations, and academic events', '#0891B2'),
('Marketing', 'Marketing conferences, digital marketing workshops, and brand events', '#65A30D');

-- Insert default notification templates
INSERT INTO notification_templates (template_name, template_type, subject_template, body_template, category) VALUES 
('EVENT_REGISTRATION_CONFIRMATION', 'EMAIL', 
 'Registration Confirmed: {{event_title}}', 
 'Hello {{user_first_name}}, your registration for {{event_title}} has been confirmed. Event starts on {{event_start_date}}.',
 'BOOKING'),
('EVENT_REMINDER_24H', 'EMAIL',
 'Reminder: {{event_title}} starts tomorrow',
 'Hello {{user_first_name}}, this is a friendly reminder that {{event_title}} starts tomorrow at {{event_start_time}}.',
 'REMINDER'),
('EVENT_FEEDBACK_REQUEST', 'EMAIL',
 'How was your experience at {{event_title}}?',
 'Hello {{user_first_name}}, we hope you enjoyed {{event_title}}. Please take a moment to share your feedback.',
 'FEEDBACK');

-- =====================================================
-- 12. CONSTRAINTS AND BUSINESS RULES
-- =====================================================

-- Ensure event end time is after start time
ALTER TABLE events ADD CONSTRAINT chk_event_datetime 
CHECK (end_datetime > start_datetime);

-- Ensure session times are within event bounds
ALTER TABLE event_sessions ADD CONSTRAINT chk_session_within_event_bounds
CHECK (start_datetime >= (SELECT start_datetime FROM events WHERE id = event_id) 
       AND end_datetime <= (SELECT end_datetime FROM events WHERE id = event_id));

-- Ensure current registrations don't exceed max attendees
ALTER TABLE events ADD CONSTRAINT chk_registrations_within_capacity 
CHECK (max_attendees IS NULL OR current_registrations <= max_attendees);

-- Ensure rating values are within valid ranges
ALTER TABLE event_feedback ADD CONSTRAINT chk_rating_ranges 
CHECK (overall_rating IS NULL OR (overall_rating >= 1 AND overall_rating <= 5));

-- Ensure sentiment scores are within valid ranges (-1.0 to 1.0)
ALTER TABLE event_feedback ADD CONSTRAINT chk_sentiment_range 
CHECK (sentiment_score IS NULL OR (sentiment_score >= -1.0 AND sentiment_score <= 1.0));

-- Ensure booking references are properly formatted (example: EVT-2024-000001)
ALTER TABLE bookings ADD CONSTRAINT chk_booking_reference_format 
CHECK (booking_reference ~ '^EVT-[0-9]{4}-[0-9]{6}$');

-- =====================================================
-- 13. VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for active events with registration info
CREATE VIEW active_events_with_stats AS
SELECT 
    e.*,
    org.name AS organization_name,
    cat.name AS category_name,
    COUNT(b.id) AS total_bookings,
    COUNT(CASE WHEN b.status = 'CONFIRMED' THEN 1 END) AS confirmed_bookings,
    COUNT(CASE WHEN b.status = 'WAITLIST' THEN 1 END) AS waitlist_count,
    AVG(ef.overall_rating) AS average_rating,
    COUNT(ef.id) AS feedback_count
FROM events e
LEFT JOIN organizations org ON e.organization_id = org.id
LEFT JOIN event_categories cat ON e.category_id = cat.id
LEFT JOIN bookings b ON e.id = b.event_id
LEFT JOIN event_feedback ef ON e.id = ef.event_id
WHERE e.status IN ('PUBLISHED', 'LIVE') 
AND e.deleted_at IS NULL
GROUP BY e.id, org.name, cat.name;

-- View for user dashboard with personalized recommendations
CREATE VIEW user_dashboard_data AS
SELECT 
    u.id AS user_id,
    u.first_name,
    u.last_name,
    COUNT(DISTINCT b.id) AS total_bookings,
    COUNT(DISTINCT CASE WHEN b.status = 'ATTENDED' THEN b.id END) AS attended_events,
    COUNT(DISTINCT ar.id) AS pending_recommendations,
    AVG(ef.overall_rating) AS average_feedback_rating,
    MAX(b.registered_at) AS last_booking_date
FROM users u
LEFT JOIN bookings b ON u.id = b.user_id
LEFT JOIN ai_recommendations ar ON u.id = ar.user_id AND ar.shown_to_user = false AND ar.expires_at > NOW()
LEFT JOIN event_feedback ef ON u.id = ef.user_id
WHERE u.deleted_at IS NULL
GROUP BY u.id, u.first_name, u.last_name;