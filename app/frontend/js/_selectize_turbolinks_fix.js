// important: filename starts with underscore to move it in the first
// position of the asset pipeline (it is important that this files methods are
// executed before all others)

// transfer knowledge about selected items from selectize to html options
var resetSelectized;

resetSelectized = function (index, select) {
  var i, len, selectedValue, val;
  selectedValue = select.tomselect.getValue();
  select.tomselect.destroy();
  $(select).find("option").attr("selected", null);
  if ($(select).prop("multiple")) {
    for (i = 0, len = selectedValue.length; i < len; i++) {
      val = selectedValue[i];
      if (val !== "") {
        $(select).find("option[value='" + val + "']").attr("selected", true);
      }
    }
  }
  else {
    if (selectedValue !== "") {
      $(select).find("option[value='" + selectedValue + "']").attr("selected", true);
    }
  }
};

function fillOptionsByAjax($selectizedSelection) {
  // TODO: this function definitely needs some refactoring
  $selectizedSelection.each(function () {
    let plugins = [];
    let send_data = false;
    let fill_path = "";
    let courseId = 0;
    let loaded = false;
    let locale = null;

    if (this.dataset.drag === "true") {
      plugins = ["remove_button", "drag_drop"];
    }
    else {
      plugins = ["remove_button"];
    }
    if (this.dataset.ajax === "true" && this.dataset.filled === "false") {
      const model_select = this;
      courseId = 0;
      const placeholder = this.dataset.placeholder;
      const no_result_msg = this.dataset.noResults;
      send_data = false;
      loaded = false;
      if (this.dataset.model === "tag") {
        locale = this.dataset.locale;
        fill_path = Routes.fill_tag_select_path({
          locale: locale,
        });
        send_data = true;
      }
      else if (this.dataset.model === "user") {
        fill_path = Routes.fill_user_select_path();
        send_data = true;
      }
      else if (this.dataset.model === "user_generic") {
        fill_path = Routes.list_generic_users_path();
      }
      else if (this.dataset.model === "teachable") {
        fill_path = Routes.fill_teachable_select_path();
      }
      else if (this.dataset.model === "medium") {
        fill_path = Routes.fill_media_select_path();
      }
      else if (this.dataset.model === "course_tag") {
        courseId = this.dataset.course;
        fill_path = Routes.fill_course_tags_path();
      }
      (function () {
        class MinimumLengthSelect extends TomSelect {
          refreshOptions(triggerDropdown = true) {
            var query = this.inputValue();
            if (query.length < 2) {
              this.close(false);
              return;
            }

            super.refreshOptions(triggerDropdown);
          }
        }
        new MinimumLengthSelect("#" + model_select.id, {
          plugins: plugins,
          valueField: "value",
          labelField: "name",
          searchField: "name",
          maxOptions: null,
          placeholder: placeholder,
          closeAfterSelect: true,
          load: function (query, callback) {
            var url;
            if (send_data || !loaded) {
              url = fill_path + "?course_id=" + courseId + "&q=" + encodeURIComponent(query);
              fetch(url).then(function (response) {
                return response.json();
              }).then(function (json) {
                loaded = true;
                return callback(json.map(function (item) {
                  return {
                    name: item.text,
                    value: item.value,
                  };
                }));
              })["catch"](function () {
                callback();
              });
            }
            callback();
          },
          render: {
            option: function (data, escape) {
              return "<div>" + '<span class="title">' + escape(data.name) + "</span>" + "</div>";
            },
            item: function (item, escape) {
              return '<div title="' + escape(item.name) + '">' + escape(item.name) + "</div>";
            },
            no_results: function (data, escape) {
              return '<div class="no-results">' + escape(no_result_msg) + "</div>";
            },
          },
        });
      })();
    }
    else {
      let renderOptions = {};

      let noResultsMessage = this.dataset.noResults;
      if (noResultsMessage) {
        renderOptions = {
          no_results: function (_data, _escape) {
            return '<div class="no-results">' + noResultsMessage + "</div>";
          },
        };
      }

      return new TomSelect("#" + this.id, {
        plugins: plugins,
        maxOptions: null,
        render: renderOptions,
      });
    }
  });
}

$(document).on("turbolinks:before-cache", function () {
  $(".tomselected").each(resetSelectized);
});

$(document).on("turbolinks:load", function () {
  fillOptionsByAjax($(".selectize"));
});
