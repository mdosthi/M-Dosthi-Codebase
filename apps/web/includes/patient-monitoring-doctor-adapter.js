(function (window, $) {
  'use strict';

  var endpoint = 'patientMonitoringApi.jsp';

  function read(op, payload) {
    return $.ajax({ url: endpoint, type: 'GET', dataType: 'json', cache: false, data: { op: op, patientId: payload.patientId } });
  }

  function write(op, payload, fields) {
    return $.ajax({ url: endpoint + '?op=' + op + '&patientId=' + encodeURIComponent(payload.patientId), type: 'POST', dataType: 'json', data: fields });
  }

  window.MDosthiMonitoringApi = $.extend(window.MDosthiMonitoringApi || {}, {
    getPatientMonitoring: function (payload) { return read('summary', payload); },
    getTherapyHistory: function (payload) { return read('therapyHistory', payload); },
    getMetastasisHistory: function (payload) { return read('metastasisHistory', payload); },
    createTherapyChange: function (payload) { return write('createTherapy', payload, payload.data); },
    createMetastasisState: function (payload) { return write('createMetastasis', payload, payload.data); },
    recordDistressAction: function (payload) { return write('createAction', payload, payload.data); }
  });
}(window, jQuery));
