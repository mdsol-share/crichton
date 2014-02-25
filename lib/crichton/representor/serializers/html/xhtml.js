$(document).ready(function () {
    get_selector().each(function (index, element) {
        $('span[itemprop]', element).each(function () {
            var attribute = $(this).attr('itemprop');
            var value = $(this).text();
            set_values(attribute, value, element);
        })
    });

    $('.custom-parameters').click(function() {
        $('.element-name').val('');
        $('.element-value').val('');
        $('.alert').hide();
        $('#modal-dialog').modal('show');
    });

    $('.btn-primary').click(function() {
        var name = $('.element-name').val(); var value = $('.element-value').val();
        if (name == '' || value == '') {
            $('.alert').show();
            return false;
        }
        $('.custom-parameters-collection')
            .append(create_div_element({ class: 'input-group ' + name + '-' + value })
                .append(create_params_label(name, value)));
        $('#modal-dialog').modal('hide');
    })

    $('form').submit(function() {
        var form = $(this);
        $('span[param-name]').each(function() {
            var name = $(this).attr('param-name');
            var value = $(this).attr('param-value');
            var input = create_input_element({ type: 'hidden', name: name, value: value });
            input.appendTo(form);
        });
        return true;
    });

    $('a').click(function() {
        var link = $(this);
        var url = link.attr('href');
        $('span[param-name]').each(function() {
            url = add_parameters_to_url(url, $(this).attr('param-name'), $(this).attr('param-value'));
        });
        link.attr('href', url);
        return true;
    });

    $('a[target]').each(function() {
        var link = $(this);
        var url = link.attr('href');
        var input = link.next('input');
        var name = input.attr('name');
        var value = input.val();
        $.ajax({
            type: 'GET',
            url: 'crichton_controller_uri?url=' + url,
            dataType: 'json',
            success: function(data) {
                var select = build_selector_group(name, value, data, link.attr('prompt'), link.attr('target'));
                select.val(value);
                link.parent('label').empty().append(select);
            }
        });
    });
});

//adds parameters key/value pair to the top of the page.
function create_params_label(name, value) {
    var content = create_span_element(build_options(name, value), name + ' : ' + value);
    var close = create_button({ class: 'close', type: 'button' }, '&times;', function() {
        var selector = '.' + name + '-' + value;
        $(selector).remove();
    }).appendTo(content);
    return content;
}

//parameters key/value pair representation
function build_options(name, value) {
    var options =  { class: 'label label-info input-group-addon' };
    options['param-name'] = name;
    options['param-value'] = value;
    return options;
}

//used to build selector from external resource
function build_selector_group(name, value, data, prompt, target) {
    var select = create_select_element({class: 'select-item', name: name});
    $.each(data, function(index, item) {
        create_option_element({value: item[target]}, item[prompt]).appendTo(select);
    });
    return select;
}

function create_div_element(options) {
    return create_element('<div/>', options);
}

function create_label_element(options, text) {
    return create_element('<label/>', options).text(text);
}

function create_input_element(options, text) {
    return create_element('<input/>', options).text(text);
}

function create_span_element(options, text) {
    return create_element('<span/>', options).text(text);
}

function create_button(options, text, click_event) {
    return create_element('<button/>', options).html(text).button().click(click_event);
}

function create_select_element(options) {
    return create_element('<select/>', options);
}

function create_option_element(options, text) {
    return create_element('<option/>', options).text(text);
}

function create_element(element, options) {
    return $(element, options)
}

function get_selector() {
    ($("ul[itemtype]").length > 1) ? selector = $("ul[itemtype]:gt(0)") : selector = $("ul[itemtype]")
    return selector
}

function add_parameters_to_url(url, key, value) {
    var re = new RegExp("([?|&])" + key + "=.*?(&|$)", "i");
    separator = url.indexOf('?') !== -1 ? "&" : "?";
    if (url.match(re)) {
        return url.replace(re, '$1' + key + "=" + value + '$2');
    }
    else {
        return url + separator + key + "=" + value;
    }
}

function set_values(attribute, value, context) {
  $('select[name="' + attribute + '"]', context).each(function (index, element) {
    var option = 'option[value="' + value + '"]'
    $(option, element).attr("selected", "selected")
  })
  $('input[name="' + attribute + '"]', context).each(function (index, element) {
    if ($(this).attr('type') == 'checkbox') {
      if (value == 'true') {
        $(this).prop('checked', value)
      }
    } else {
      $(this).val(value)
    }
  })
}

function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}
