$(document).ready(function () {
    get_selector().each(function (index, element) {
        $('span[itemprop]', element).each(function () {
            var attribute = $(this).attr('itemprop');
            var value = $(this).text();
            set_values(attribute, value, element);
        })
    });

    $('.custom-parameters').click(function(){
        create_modal('Additional Parameters', 'param', '.custom-parameters-collection');
        $('.modal-body').append(build_control_group('name'));
        $('.modal-body').append(build_control_group('value'));
    });

    $('.custom-headers').click(function(){
        create_modal('Custom Headers', 'header', '.custom-headers-collection');
        $('.modal-body').append(build_control_group('name'));
        $('.modal-body').append(build_control_group('value'));
    });

    $('.save').click(function() {
        var name = $('.element-name').val();
        var value = $('.element-value').val();
        if (name == '' || value == '') {
            $('.alert').show();
            return false;
        }
        var input = $('input[type="hidden"]');
        var container = input.attr('container');
        var subtype = input.attr('subtype');
        var div = create_div_element({ class: 'input-group ' + subtype + '-' + name });
        $(container).append(div.append(create_params_label(subtype, name, value)));
        $('#modal-dialog').modal('hide');
    })

    $('form').submit(function() {
        add_fields_to_the_form($(this));
        $.ajax({
            type: $(this).attr('method'),
            url: $(this).attr('action'),
            data: $(this).serialize(),
            dataType: 'html',
            beforeSend: function(xhr, settings) {
                beforesend_callback(xhr, settings);
            },
            success: function(data, status, xhr) {
                success_callback(data);
            }
        });
        return false;
    });

    $('a').click(function() {
        var url = add_parameters_to_url($(this).attr('href'));
        $(this).attr('href', url);
        $.ajax({
            type: 'GET',
            url: url,
            beforeSend: function(xhr, settings) {
                beforesend_callback(xhr, settings);
            },
            success: function(data) {
                success_callback(data);
            }
        });
        return false;
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

function beforesend_callback(xhr, settings) {
    xhr.setRequestHeader('Cache-Control', 'no-cache');
    $('span[header-name]').each(function() {
        xhr.setRequestHeader($(this).attr('header-name'), $(this).attr('header-value'));
    });
}

function success_callback(data) {
    var content = $(data).filter('.main-content');
    $('.main-content').replaceWith(content);
}

function add_fields_to_the_form(form){
    $('span[param-name]').each(function() {
        var name = $(this).attr('param-name')
        var value = $(this).attr('param-value')
        var input = create_input_element({ type: 'hidden', name: name, value: value })
        input.appendTo(form);
    });
}

function add_parameters_to_url(url){
    $('span[param-name]').each(function() {
        url = update_url(url, $(this).attr('param-name'), $(this).attr('param-value'));
    });
    return url;
}

function create_modal(title, subtype, container){
    var modal_object = initialize_modal(title);
    var hidden = create_input_element({ type: 'hidden', subtype: subtype, container: container });
    hidden.appendTo(modal_object)
    modal_object.modal('show');
}

function initialize_modal(title){
    var modal_object = $('#modal-dialog');
    $('.modal-title').text(title);
    $('.modal-body').empty();
    $('.modal-body').append(build_alert_message());
    $('input[subtype]').remove();
    $('.alert').hide();
    return modal_object;
}

//used to build label/input control group within bootstrap control-group element
function build_control_group(element_group){
    var div_control_group = create_div_element({ class: 'control-group' });
    var label = create_label_element({ for: element_group }, capitalizeFirstLetter(element_group));
    var div_controls = create_div_element({ class: 'controls' });
    var input = create_input_element({ class: 'span5 element-' + element_group, type: 'text', name: 'value' });
    var span = create_span_element({ class: 'help-block hide' });

    span.appendTo(div_controls);
    input.appendTo(div_controls);
    label.appendTo(div_control_group);
    div_controls.appendTo(div_control_group);
    return div_control_group;
}

function build_alert_message(){
    return create_div_element({ class: 'alert alert-warning' })
        .text("Warning! Input fields can't be blank!");
}

//adds parameters key/value pair to the top of the page.
function create_params_label(subtype, name, value) {
    var content = create_span_element(build_options(subtype, name, value), name + ' : ' + value);
    var close = create_button({ class: 'close', type: 'button' }, '&times;', function() {
        var selector = '.' + subtype + '-' + name;
        $(selector).remove();
    }).appendTo(content);
    return content;
}

//parameters key/value pair representation
function build_options(subtype, name, value) {
    var subtype_name = subtype + '-name';
    var subtype_value = subtype + '-value';
    var options =  { class: 'label label-info input-group-addon' };
    options[subtype_name] = name;
    options[subtype_value] = value;
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
    return $(element, options);
}

function get_selector() {
    ($("ul[itemtype]").length > 1) ? selector = $("ul[itemtype]:gt(0)") : selector = $("ul[itemtype]")
    return selector;
}

function update_url(url, key, value) {
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
