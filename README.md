🏋️‍♂️ Gym Management System

A full-stack intelligent Gym Management Platform that connects administrators, coaches, and clients in a unified ecosystem. The system manages gyms, memberships, attendance, subscriptions, scheduling, community engagement, notifications, and AI-powered churn prediction for retention optimization.

🚀 Features
🏢 Gym Management
Create and manage gym profiles (name, location, contact info, machines, subscription plans)
Activate, update, or deactivate gyms
Assign coaches and clients to gyms
🔐 Authentication & Authorization
Role-based access control (Admin / Coach / Client)
Secure login & registration
Email verification with activation link
Restricted access until verification is completed
👤 Client Management
Personal fitness profiles
Update fitness goals and personal data
View profile and activity history
💳 Subscription System
Subscription tracking (start/end dates)
Renewal and expiration handling
Notifications for subscription status
Admin-controlled subscription management
📊 Attendance System (QR-Based)
Unique QR code per gym
Clients scan QR to check-in
Automatic attendance logging (Client ID, Gym ID, timestamp)
Prevention of duplicate daily attendance
Block access for expired/suspended memberships
🧑‍🏫 Coach & Timetable Management
Coach profiles across multiple gyms
Personal coach schedules
Admin-approved class scheduling requests
Gym-wide timetable visibility
Client personal timetable view
🏃‍♂️ Class Enrollment System
Class capacity control
Real-time slot availability
Enrollment conflict prevention
Cancel enrollment before class start
💬 Community System
Gym-specific private community spaces
Member-only access per gym
🔔 Notifications & Announcements
Gym announcements (Admin)
Email + in-app notifications
Class reminders and schedule updates
📈 Dashboard & Reporting
Admin analytics (revenue, attendance, subscriptions)
User activity summaries
Attendance tracking reports
🧠 AI Personalized Training Plans
Fitness goal-based plan generation
Activity-aware recommendations
Personalized gym programs
🏅 Gamification System
Attendance-based badges
Weekly/monthly streak rewards
Engagement achievements stored in profiles
🤖 Churn Prediction Model
ML model predicts member churn risk:
LOW / MED / HIGH risk
Uses attendance, subscription, engagement data
On-demand prediction during retention campaigns
Historical prediction tracking
🎯 Retention Offer System
Admin-generated retention offers (discounts, free sessions, supplements)
ML-based targeted selection of members
Admin review before sending offers
Excludes users with active offers
⚙️ Non-Functional Requirements
⚡ Performance
Response time < 2 seconds (95% requests)
Supports 1,000+ concurrent users
Efficient mobile usage (< 50MB app size)
🔐 Security
JWT-based authentication
Role-based access control (RBAC)
AES-256 encryption for sensitive data
Secure password hashing
📱 Usability
Mobile-first UI (Android & iOS)
Simple, intuitive UX for non-technical users
Clear error handling and messages
🛡 Reliability
Daily automated backups (30-day retention)
Fault tolerance and recovery mechanisms
📈 Scalability
Supports scaling up to 10,000 users
Handles up to 1M+ records
🔄 Compatibility
Frontend: Flutter (Android 8+, iOS 12+)
Backend: FastAPI
Database: Supabase (PostgreSQL)
🤖 ML Requirements
≥ 75% churn prediction accuracy
Prediction completes within 30 seconds
Predictions are advisory (admin-controlled actions)
🏗 Tech Stack
Frontend: Flutter
Backend: FastAPI (Python)
Database: Supabase (PostgreSQL)
Authentication: JWT + Email Verification
Notifications: Firebase Cloud Messaging + Email Service
ML Model: Python (Scikit-learn / TensorFlow)
📦 System Architecture
Mobile App (Flutter)
RESTful API (FastAPI)
PostgreSQL Database (Supabase)
ML Prediction Service
Notification Service (Email + Push)
📊 Key Modules
Gym Management Module
User Authentication Module
Subscription & Attendance Module
Scheduling & Enrollment Module
Community Module
Notification Module
Analytics Dashboard
ML Churn Prediction Engine
📌 Future Enhancements
Real-time chat between coaches and clients
Wearable device integration
Advanced AI fitness coaching assistant
Payment gateway integration
Live class streaming support
👨‍💻 Authors

Developed as a full-stack gym ecosystem project covering:

Backend engineering (FastAPI)
Mobile development (Flutter)
Database design (PostgreSQL/Supabase)
Machine learning integration
