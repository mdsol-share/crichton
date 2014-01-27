$(document).ready(function () {
    get_selector().each(function (index, element) {
        $('span[itemprop]', element).each(function () {
            var attribute = $(this).attr('itemprop');
            var value = $(this).text();
            set_values(attribute, value, element);
        })
    });
})

function get_selector() {
    ($("ul[itemtype]").length > 1) ? selector = $("ul[itemtype]:gt(0)") : selector = $("ul[itemtype]");
    return selector;
}

function set_values(attribute, value, context) {
  $('select[name="' + attribute + '"]', context).each(function (index, element) {
    var option = 'option[value="' + value + '"]';
    $(option, element).attr("selected", "selected");
  })
  $('input[name="' + attribute + '"]', context).each(function (index, element) {
    if ($(this).attr('type') == 'checkbox') {
      if (value == 'true') {
        $(this).prop('checked', value);
      } 
    } else {
      $(this).val(value);
    }
  })
}
