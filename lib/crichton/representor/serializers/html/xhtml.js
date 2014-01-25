$(document).ready(function () {
    get_selector().each(function (index, element) {
        $('span[itemprop]', element).each(function () {
            var attribute = $(this).attr('itemprop');
            var value = $(this).text();
            set_values(attribute, value, element);
        })
    })

    $('.custom-headers').click(function(){
        create_modal('Request Headers', 'header', '.custom-header-collection');
    })

    $('.custom-parameters').click(function(){
        create_modal('Additional Parameters', 'param', '.custom-parameter-collection');
    })

    $('.add-value').click(function(){
        add_element($('.element-name').val(), $('.element-value').val())
    })
})

function create_modal(title, subtype, container){
    initialize_modal(title);
    var modal_object = $('#modal-dialog');
    var hidden = create_element('<input/>', {type: 'hidden', subtype: subtype, container: container});
    hidden.appendTo(modal_object)
    modal_object.modal('show');
}

function initialize_modal(title){
    $('.element-name').val(''); $('.element-value').val('');
    $('.modal-title').text(title);
    $('input[type="hidden"]').remove();
}

function add_element(name, value){
    var input = $('input[type="hidden"]');
    var container = input.attr('container');
    var content = create_element('<span/>', build_options(input)).text(name + ' : ' + value);
    content.appendTo(container);
    close_dialog();
}

function build_options(input) {
    var subtype_name = input.attr('subtype') + '-name';
    var subtype_value = input.attr('subtype') + '-value';
    var options =  { class: 'span5 label label-success' };
    options[subtype_name] = name;
    options[subtype_value] = value;
    return options;
}

function create_element(element, options) {
    return $(element, options)
}

function close_dialog(){
    $('#modal-dialog').modal('hide');
}

function get_selector() {
    ($("ul[itemtype]").length > 1) ? selector = $("ul[itemtype]:gt(0)") : selector = $("ul[itemtype]")
    return selector
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
