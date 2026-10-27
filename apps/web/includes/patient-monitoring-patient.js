(function ($) {
  'use strict';

  var root = $('.patient-monitoring').last();
  var patientId = root.data('patient-id');
  var service = window.MDosthiMonitoringService;

  function showMessage(text, type) {
    $('#patient-monitoring-message')
      .removeClass('alert-success alert-danger')
      .addClass('alert-' + type)
      .text(text)
      .show();
  }

  function escapeHtml(value) {
    return $('<div>').text(value == null ? '' : value).html();
  }

  function showError(target) {
    $(target).html('<div class="monitoring-error">Unable to load monitoring data. Please try again.</div>');
  }

  function renderTable(target, records, columns, emptyText) {
    if (!records || !records.length) {
      $(target).html('<div class="monitoring-empty">' + emptyText + '</div>');
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

    $(target).html(table + '</tbody></table></div>');
  }

  function renderActivities(records) {
    if (!records || !records.length) {
      $('#activity-list').html('<div class="monitoring-empty">No records available yet.</div>');
      return;
    }

    var today = new Date().toISOString().slice(0, 10);
    var groups = {
      today: [],
      upcoming: [],
      completed: []
    };

    records.forEach(function (activity) {
      if (activity.status === 'Completed') {
        groups.completed.push(activity);
      } else if (activity.date === today) {
        groups.today.push(activity);
      } else {
        groups.upcoming.push(activity);
      }
    });

    function rows(items, allowCompletion) {
      if (!items.length) {
        return '<p class="monitoring-empty">No records available yet.</p>';
      }

      return '<div class="table-responsive"><table class="table table-striped"><thead><tr><th>Activity</th><th>Date / time</th><th>Duration</th><th>Status</th><th></th></tr></thead><tbody>' + items.map(function (activity) {
        var completionButton = allowCompletion && activity.id ? '<button type="button" class="btn btn-xs btn-success complete-activity" data-activity-id="' + escapeHtml(activity.id) + '">Mark as Completed</button>' : '';
        return '<tr><td>' + escapeHtml(activity.name) + '</td><td>' + escapeHtml(activity.date) + ' ' + escapeHtml(activity.startTime) + '</td><td>' + escapeHtml(activity.duration) + ' minutes</td><td>' + escapeHtml(activity.status) + '</td><td>' + completionButton + '</td></tr>';
      }).join('') + '</tbody></table></div>';
    }

    $('#activity-list').html('<h4>Today\'s Activities</h4>' + rows(groups.today, true) + '<h4>Upcoming Activities</h4>' + rows(groups.upcoming, true) + '<h4>Completed Activities</h4>' + rows(groups.completed, false));
  }

  function loadSleepRecords() {
    service.getSleepRecords(patientId)
      .done(function (data) {
        renderTable('#sleep-history', data && data.records, [
          { key: 'sleepDate', label: 'Date' },
          { key: 'duration', label: 'Duration' },
          { key: 'quality', label: 'Quality' }
        ], 'No records available yet.');
      })
      .fail(function () {
        showError('#sleep-history');
      });
  }

  function loadMoodRecords() {
    service.getMoodRecords(patientId)
      .done(function (data) {
        renderTable('#mood-history', data && data.records, [
          { key: 'date', label: 'Date' },
          { key: 'mood', label: 'Mood' },
          { key: 'notes', label: 'Notes' }
        ], 'No records available yet.');
      })
      .fail(function () {
        showError('#mood-history');
      });
  }

  function loadActivities() {
    service.getActivities(patientId)
      .done(function (data) {
        renderActivities(data && data.records);
      })
      .fail(function () {
        showError('#activity-list');
      });
  }

  function load() {
    loadSleepRecords();
    loadMoodRecords();
    loadActivities();
  }

  $('#sleep-form').on('submit', function (event) {
    event.preventDefault();

    var form = this;
    $('#sleep-error').text('');

    if (!form['sleep-date'].value) {
      $('#sleep-error').text('Sleep date is required.');
      return;
    }

    if (form['sleep-duration'].value && (form['sleep-duration'].value < 0 || form['sleep-duration'].value > 24)) {
      $('#sleep-error').text('Enter a duration between 0 and 24 hours.');
      return;
    }

    service.createSleepRecord(patientId, {
      sleepDate: form['sleep-date'].value,
      bedtime: form.bedtime.value,
      wakeTime: form['wake-time'].value,
      duration: form['sleep-duration'].value,
      quality: form['sleep-quality'].value,
      awakenings: form.awakenings.value,
      difficultySleeping: $('#difficulty-sleeping').prop('checked'),
      notes: $('#sleep-notes').val()
    }).done(function () {
      showMessage('Information saved successfully.', 'success');
      form.reset();
      load();
    }).fail(function () {
      showMessage('Unable to save monitoring data. Please try again.', 'danger');
    });
  });

  $('#mood-form').on('submit', function (event) {
    event.preventDefault();

    var mood = $('input[name="mood"]:checked').val();
    $('#mood-error').text('');

    if (!mood) {
      $('#mood-error').text('Select a mood value.');
      return;
    }

    service.createMoodRecord(patientId, {
      mood: mood,
      intensity: $('#mood-intensity').val(),
      notes: $('#mood-notes').val()
    }).done(function () {
      showMessage('Your mood has been recorded.', 'success');
      $('#mood-form')[0].reset();
      load();
    }).fail(function () {
      showMessage('Unable to save monitoring data. Please try again.', 'danger');
    });
  });

  $('#activity-form').on('submit', function (event) {
    event.preventDefault();

    var form = this;
    $('#activity-error').text('');

    if (!form['activity-name'].value.trim() || !form['activity-category'].value || !form['activity-date'].value || !form['activity-time'].value || !form['activity-duration'].value) {
      $('#activity-error').text('Activity name, category, date, time, and duration are required.');
      return;
    }

    service.createActivity(patientId, {
      name: form['activity-name'].value,
      category: form['activity-category'].value,
      date: form['activity-date'].value,
      startTime: form['activity-time'].value,
      duration: form['activity-duration'].value,
      status: form['activity-status'].value,
      notes: $('#activity-notes').val()
    }).done(function () {
      showMessage('Information saved successfully.', 'success');
      form.reset();
      loadActivities();
    }).fail(function () {
      showMessage('Unable to save monitoring data. Please try again.', 'danger');
    });
  });

  $('#activity-list').on('click', '.complete-activity', function () {
    var activityId = $(this).data('activity-id');

    service.completeActivity(patientId, activityId)
      .done(function () {
        showMessage('Information saved successfully.', 'success');
        loadActivities();
      })
      .fail(function () {
        showMessage('Unable to save monitoring data. Please try again.', 'danger');
      });
  });

  load();
}(jQuery));