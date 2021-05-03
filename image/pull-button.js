define(function () {
  var $ = require("jquery");
  var utils = require("base/js/utils");
  var events = require("base/js/events");
  var baseUrl = utils.get_body_data("baseUrl");

  function updateAll() {
    var url = utils.url_path_join(baseUrl, "api/pull-repos");
    utils.ajax(url, {
      processData: false,
      cache: false,
      type: "POST",
      success: function () {
        console.log("Updated repos...");
      },
      error: function () {
        console.error("Failed to update repos");
      },
    });
  }

  function pullButton() {
    if ($(".tree-buttons").length === 0) {
      events.on("app_initialized.NotebookListApp", pullButton);
      return;
    }
    if ($("#pull-repos").length === 0) {
      $(".tree-buttons > .pull-right").append(
        $("<div>")
          .addClass("btn-group")
          .append(
            $("<button>")
              .addClass("btn btn-default btn-xs")
              .click(updateAll)
              .attr("title", "Update repos")
              .append($("<i>").addClass("fa fa-download"))
          )
      );
    }
  }

  function load_ipython_extension() {
    pullButton();
  }

  return {
    load_ipython_extension: load_ipython_extension,
  };
});
