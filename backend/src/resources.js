// Only these identifiers can become SQL table names. Never interpolate user input.
const owner = ['petOwner', 'staff', 'doctor', 'systemAdmin'];
const clinic = ['staff', 'doctor', 'systemAdmin'];
const admin = ['systemAdmin'];
const resources = {
  clinic_directory: { roles: owner, scope: 'clinic', writers: [] },
  owner_profiles: { roles: ['petOwner'], scope: 'private' },
  pets: { roles: owner, scope: 'owner' },
  appointments: { roles: owner, scope: 'owner' },
  queue_entries: { roles: owner, scope: 'owner' },
  home_visits: { roles: owner, scope: 'owner' },
  pet_care_bookings: { roles: owner, scope: 'owner' },
  emergency_requests: { roles: owner, scope: 'owner' },
  reminders: { roles: owner, scope: 'owner' },
  owner_notifications: { roles: owner, scope: 'owner' },
  clinic_messages: { roles: owner, scope: 'owner' },
  saved_addresses: { roles: ['petOwner'], scope: 'private' },
  notification_settings: { roles: ['petOwner'], scope: 'private' },
  support_tickets: { roles: owner, scope: 'owner' },
  history_reviews: { roles: ['petOwner'], scope: 'private' },
  saved_first_aid_guides: { roles: ['petOwner'], scope: 'private' },
  doctor_profiles: { roles: ['doctor'], scope: 'private' },
  doctor_appointment_state: { roles: clinic, scope: 'clinic' },
  // Pet owners can READ their pets' medical/treatment records (uploaded by
  // clinic staff/doctors). Only clinic roles may write them.
  medical_records: { roles: owner, scope: 'clinic', writers: clinic },
  health_posts: { roles: owner, scope: 'clinic', writers: clinic },
  health_post_drafts: { roles: ['doctor'], scope: 'private' },
  doctor_notifications: { roles: ['doctor'], scope: 'private' },
  walk_in_appointments: { roles: clinic, scope: 'clinic' },
  payments: { roles: ['staff', 'systemAdmin'], scope: 'clinic' },
  inventory: { roles: owner, scope: 'clinic', writers: clinic },
  staff_profiles: { roles: ['staff'], scope: 'private' },
  user_directory: { roles: admin, scope: 'clinic' },
  doctor_verifications: { roles: admin, scope: 'clinic' },
  audit_logs: { roles: admin, scope: 'clinic', appendOnly: true },
  admin_profiles: { roles: admin, scope: 'private' },
};
module.exports = { resources };
