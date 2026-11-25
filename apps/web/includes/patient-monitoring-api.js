(function (window, $) {
  'use strict';

  var adapter = window.MDosthiMonitoringApi || {};

  function unavailable(operation) {
    return $.Deferred().reject({
      monitoringApiUnavailable: true,
      operation: operation,
      message: 'Monitoring API is not available yet.'
    }).promise();
  }

  function invoke(operation, payload) {
    if (typeof adapter[operation] === 'function') {
      return adapter[operation](payload || {});
    }
    return unavailable(operation);
  }

  window.MDosthiMonitoringService = {
    getPatientMonitoring: function (patientId) { return invoke('getPatientMonitoring', { patientId: patientId }); },
    getPatientDistress: function (patientId) { return invoke('getPatientDistress', { patientId: patientId }); },
    getTherapyHistory: function (patientId) { return invoke('getTherapyHistory', { patientId: patientId }); },
    createTherapyChange: function (patientId, data) { return invoke('createTherapyChange', { patientId: patientId, data: data }); },
    getMetastasisHistory: function (patientId) { return invoke('getMetastasisHistory', { patientId: patientId }); },
    createMetastasisState: function (patientId, data) { return invoke('createMetastasisState', { patientId: patientId, data: data }); },
    recordDistressAction: function (patientId, data) { return invoke('recordDistressAction', { patientId: patientId, data: data }); },
    getSleepRecords: function (patientId) { return invoke('getSleepRecords', { patientId: patientId }); },
    createSleepRecord: function (patientId, data) { return invoke('createSleepRecord', { patientId: patientId, data: data }); },
    getMoodRecords: function (patientId) { return invoke('getMoodRecords', { patientId: patientId }); },
    createMoodRecord: function (patientId, data) { return invoke('createMoodRecord', { patientId: patientId, data: data }); },
    getActivities: function (patientId) { return invoke('getActivities', { patientId: patientId }); },
    createActivity: function (patientId, data) { return invoke('createActivity', { patientId: patientId, data: data }); },
    updateActivity: function (patientId, activityId, data) { return invoke('updateActivity', { patientId: patientId, activityId: activityId, data: data }); },
    completeActivity: function (patientId, activityId) { return invoke('completeActivity', { patientId: patientId, activityId: activityId }); },
    getEducationContent: function () { return invoke('getEducationContent'); },
    getCBTContent: function () { return invoke('getCBTContent'); },
    getCognitiveDistortionContent: function () { return invoke('getCognitiveDistortionContent'); }
  };
}(window, jQuery));