const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  bookingTimeMinutes,
  bookingIntervalsOverlap,
  sameAppointmentDoctor,
  appointmentScheduleError,
} = require('../src/api');

test('parses booking times and detects duration overlap', () => {
  assert.equal(bookingTimeMinutes('12:30 PM'), 12 * 60 + 30);
  assert.equal(bookingTimeMinutes('9:00 AM'), 9 * 60);
  assert.equal(bookingIntervalsOverlap(
    { time: '9:00 AM', service: { durationMinutes: 60 } },
    { time: '9:30 AM', service: { durationMinutes: 30 } },
  ), true);
  assert.equal(bookingIntervalsOverlap(
    { time: '9:00 AM', service: { durationMinutes: 60 } },
    { time: '10:00 AM', service: { durationMinutes: 30 } },
  ), false);
  assert.equal(sameAppointmentDoctor(
    { veterinarianId: 'doctor-1', veterinarian: 'Old Name' },
    { veterinarianId: 'doctor-1', veterinarian: 'New Name' },
  ), true);
});

test('schedule rule rejects leave, breaks, off-hours and shift overflow', () => {
  const profile = {
    acceptingAppointments: true,
    leaveDates: ['2030-01-08T00:00:00.000Z'],
    schedule: {
      monday: {
        isWorking: true,
        startMinutes: 9 * 60,
        endMinutes: 17 * 60,
        breakStartMinutes: 12 * 60,
        breakEndMinutes: 13 * 60,
      },
    },
  };
  assert.match(appointmentScheduleError({
    profile, date: '2030-01-08', time: '10:00 AM', durationMinutes: 60,
  }), /leave/i);
  assert.match(appointmentScheduleError({
    profile, date: '2030-01-07', time: '11:30 AM', durationMinutes: 60,
  }), /working schedule/i);
  assert.match(appointmentScheduleError({
    profile, date: '2030-01-07', time: '4:30 PM', durationMinutes: 60,
  }), /working schedule/i);
  assert.equal(appointmentScheduleError({
    profile, date: '2030-01-07', time: '1:00 PM', durationMinutes: 60,
  }), null);
});
