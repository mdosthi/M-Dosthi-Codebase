(function ($) {
  'use strict';

  var root = $('.patient-monitoring').last();
  var patientId = root.data('patient-id');
  var service = window.MDosthiMonitoringService;

  function showMessage(text, type) {
    $('#doctor-monitoring-message')
      .removeClass('alert-success alert-danger alert-warning')
      .addClass('alert-' + type)
      .text(text)
      .show();
  }

  function showUnavailable(panel) {
    $(panel).html('<div class="monitoring-error">Unable to load monitoring data. Please try again.</div>');
  }

  function escapeHtml(value) {
    return $('<div>').text(value == null ? '' : value).html();
  }

  function renderHistory(panel, records, columns, emptyText) {
    if (!records || !records.length) {
      $(panel).html('<div class="monitoring-empty">' + emptyText + '</div>');
      return;
    }

    var table = '<div class="table-responsive"><table class="table table-striped monitoring-history"><thead><tr>';

    columns.forEach(function (column) {
      table += '<th>' + column.label + '</th>';
    });

    table += '</tr></thead><tbody>';

    records.forEach(function (record) {
      table += '<tr>';
      columns.forEach(function (column) {
        table += '<td>' + escapeHtml(record[column.key]) + '</td>';
      });
      table += '</tr>';
    });

    $(panel).html(table + '</tbody></table></div>');
  }

  function renderDistress(distress) {
    if (!distress) {
      $('#distress-status-panel').html('<div class="monitoring-empty">No records available yet.</div>');
      return;
    }

    var statusClass = distress.status === 'High' ? 'high' : '';
    var statusHtml = '<p><span class="monitoring-status ' + statusClass + '">' + escapeHtml(distress.status) + '</span></p>';
    statusHtml += '<p>Score: ' + escapeHtml(distress.score) + '</p>';
    statusHtml += '<p>Assessment date: ' + escapeHtml(distress.assessmentDate) + '</p>';
    $('#distress-status-panel').html(statusHtml);

    if (distress.physicalMeetingRecommended) {
      $('#distress-action-section').show();
    }
  }

  function loadMonitoringSummary() {
    service.getPatientMonitoring(patientId)
      .done(function (data) {
        var summary = data && data.summary ? '<p>' + escapeHtml(data.summary) + '</p>' : '<div class="monitoring-empty">No records available yet.</div>';
        $('#patient-summary-panel').html(summary);
        $('#current-therapy').text(data && data.currentTherapy ? data.currentTherapy : 'Not available');
        renderDistress(data && data.distress);
      })
      .fail(function () {
        showUnavailable('#patient-summary-panel');
        showUnavailable('#distress-status-panel');
      });
  }

  function loadTherapyHistory() {
    service.getTherapyHistory(patientId)
      .done(function (data) {
        renderHistory('#therapy-history-panel', data && data.records, [
          { key: 'dateOfChange', label: 'Date' },
          { key: 'previousTherapy', label: 'Previous therapy' },
          { key: 'newTherapy', label: 'New therapy' },
          { key: 'reason', label: 'Reason' }
        ], 'No therapy changes have been recorded.');
      })
      .fail(function () {
        showUnavailable('#therapy-history-panel');
      });
  }

  function loadMetastasisHistory() {
    service.getMetastasisHistory(patientId)
      .done(function (data) {
        renderHistory('#metastasis-history-panel', data && data.records, [
          { key: 'recordedAt', label: 'Date' },
          { key: 'state', label: 'State' }
        ], 'No records available yet.');
      })
      .fail(function () {
        showUnavailable('#metastasis-history-panel');
      });
  }

  function load() {
    if (!patientId) {
      showMessage('Select a patient before opening Patient Monitoring.', 'warning');
      return;
    }

    loadMonitoringSummary();
    loadTherapyHistory();
    loadMetastasisHistory();
  }

  $('#therapy-change-form').on('submit', function (event) {
    event.preventDefault();

    var form = this;
    $('#new-therapy-error, #therapy-date-error').text('');

    if (!form.newTherapy.value.trim()) {
      $('#new-therapy-error').text('New therapy is required.');
      return;
    }

    if (!form.dateOfChange.value) {
      $('#therapy-date-error').text('Date of change is required.');
      return;
    }

    service.createTherapyChange(patientId, {
      previousTherapy: form.previousTherapy.value,
      newTherapy: form.newTherapy.value,
      reason: form.reason.value,
      dateOfChange: form.dateOfChange.value
    }).done(function () {
      showMessage('Information saved successfully.', 'success');
      form.reset();
      load();
    }).fail(function () {
      showMessage('Unable to save monitoring data. Please try again.', 'danger');
    });
  });

  $('#metastasis-form').on('submit', function (event) {
    event.preventDefault();

    var form = this;
    $('#metastasis-error').text('');

    if (!form.state.value.trim()) {
      $('#metastasis-error').text('Metastasis state is required.');
      return;
    }

    service.createMetastasisState(patientId, { state: form.state.value })
      .done(function () {
        showMessage('Information saved successfully.', 'success');
        form.reset();
        load();
      })
      .fail(function () {
        showMessage('Unable to save monitoring data. Please try again.', 'danger');
      });
  });

  $('#distress-action-form').on('submit', function (event) {
    event.preventDefault();

    var form = this;
    if (!form.action.value) {
      return;
    }

    service.recordDistressAction(patientId, {
      action: form.action.value,
      remarks: form.remarks.value
    }).done(function () {
      showMessage('Information saved successfully.', 'success');
    }).fail(function () {
      showMessage('Unable to save monitoring data. Please try again.', 'danger');
    });
  });

  load();
}(jQuery));