$(document).ready(function () {
    get_selector().each(function (index, element) {
        $('span[itemprop]', element).each(function () {
            var attribute = $(this).attr('itemprop');
            var value = $(this).text();
            set_values(attribute, value, element);
        })
    });

    $('.custom-parameters').click(function(){
        create_modal('Additional Parameters', 'param', '.custom-parameter-collection');
        $('.modal-body').append(build_control_group('name'));
        $('.modal-body').append(build_control_group('value'));
        $('.modal-footer').append(create_button({ type: 'button', class: 'btn btn-primary' }, 'Save Changes', function(){
            add_element($('.element-name').val(), $('.element-value').val());
        }));
    });

    $('form').submit(function(){
        var form = $(this);
        $('span[param-name]').each(function(){
            var subtype = $('input[subtype]').attr('subtype');
            var name = $(this).attr(subtype+'-name')
            var value = $(this).attr(subtype+'-value')
            var input = create_input_element({ type: 'hidden', name: name, value: value })
            input.appendTo(form);
        });
        return true;
    });

    $('a').click(function(){
        var link = $(this);
        var url = link.attr('href');
        var subtype = $('input[subtype]').attr('subtype');
        $('span[param-name]').each(function(){
            url = add_parameters_to_url(url, $(this).attr(subtype+'-name'), $(this).attr(subtype+'-value'));
        });
        link.attr('href', url);
        return true;
    });

    $('a[target]').click(function() {
        var link = $(this);
        var url = link.attr('href');
        $.getJSON(url, function(data){
            $('.modal-body').append(build_selector_group(data, link.attr('prompt'), link.attr('target')));
        })
        create_modal('Select Item', 'selector', '.custom-selector-collection');
        $('.modal-footer').append(create_button({ type: 'button', class: 'btn btn-primary' }, 'Select', function(){
            var selected_item = $('.select-item').val();
            if (selected_item != -1) {
                link.next('input').val(selected_item);
                close_dialog();
            } else {
                alert('Select valid item!');
            }
        }));
        return false;
    });
})

function initialize_modal(title){
    var modal_object = $('#modal-dialog');
    $('.modal-body').empty();
    $('.modal-title').text(title);
    $('.btn-primary').remove();
    return modal_object;
}

function create_modal(title, subtype, container){
    var modal_object = initialize_modal(title);
    var hidden = create_input_element({ type: 'hidden', subtype: subtype, container: container });
    hidden.appendTo(modal_object)
    modal_object.modal('show');
}

function close_dialog(){
    $('#modal-dialog').modal('hide');
    $('.btn-primary').remove();
}

//adds parameters key/value pair to the top of the page.
function add_element(name, value){
    var input = $('input[type="hidden"]');
    var container = input.attr('container');
    var div = create_div_element({ class: 'input-group ' + name + '-' + value });
    var content = create_span_element(build_options(input, name, value), name + ' : ' + value);
    var close = create_button({ class: 'close', type: 'button' }, '&times;', function(){
        var selector = '.' + name + '-' + value;
        $(selector).remove();
    });
    close.appendTo(content);
    content.appendTo(div);
    div.appendTo(container);
    close_dialog();
}

//parameters key/value pair representation
function build_options(input, name, value) {
    var subtype_name = input.attr('subtype') + '-name';
    var subtype_value = input.attr('subtype') + '-value';
    var options =  { class: 'label label-info input-group-addon' };
    options[subtype_name] = name;
    options[subtype_value] = value;
    return options;
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

//used to build selector from external resource
function build_selector_group(data, prompt, target){
    var div_control_group = create_div_element({ class: 'control-group' });
    var select = create_select_element({class: 'select-item'});
    create_option_element({ value: -1 }, 'Select item...').appendTo(select);
    $.each(data, function(index, item){
        create_option_element({value: item[target]}, item[prompt]).appendTo(select);
    });

    return div_control_group.append(select);
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

function create_span_element(options, text){
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
    var params = key + '=' + value;
    if (url.indexOf('?') > 0) {
        return url + "&" + params;
    } else {
        return url + "?" + params;
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
