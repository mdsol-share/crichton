$(document).ready(function () {
    var crichtonAjax = {
        buildSelectorCallback: function(name, value, link) {
            var result = function(data) {
                var select = buildSelectorGroup(name, value, data, link.attr('prompt'), link.attr('target'));
                select.val(value);
                link.parent('label').empty().append(select);
            }
            return result;
        },

        updateBrowserUrl: function(context) {
            var selfHref = $('a[rel="self"]', context).attr('href');
            history.pushState({}, '', selfHref);
        },

        replaceCallback: function(selector) {
            var result = function(data) {
                var content = $(data).filter(selector);
                $(selector).replaceWith(content);
                crichtonAjax.updateBrowserUrl(content);
            }
            return result;
        },

        beforeSendCallback: function(xhr, settings) {
            xhr.setRequestHeader('Cache-Control', 'no-cache');
            $('span[header-name]').each(function() {
                xhr.setRequestHeader($(this).attr('header-name'), $(this).attr('header-value'));
            });
        },

        call: function(method, url, send, dataType) {
            var result = function(success){
                $.ajax({
                    type: method,
                    url: url,
                    data: send,
                    dataType: dataType,
                    beforeSend: crichtonAjax.beforeSendCallback,
                    success: success
                });
            };
            return result;
        }
    };

    getSelector().each(function (index, element) {
        $('span[itemprop]', element).each(function () {
            var attribute = $(this).attr('itemprop');
            var value = $(this).text();
            setValues(attribute, value, element);
        })
    });

    $('.custom-parameters').click(function() {
        createModal('Additional Parameters', 'param', '.custom-parameters-collection');
        $('.modal-body').append(buildControlGroup('name'));
        $('.modal-body').append(buildControlGroup('value'));
    });

    $('.custom-headers').click(function() {
        createModal('Custom Headers', 'header', '.custom-headers-collection');
        $('.modal-body').append(buildControlGroup('name'));
        $('.modal-body').append(buildControlGroup('value'));
    });

    $('.save').click(function() {
        var name = $('.element-name').val(),
            value = $('.element-value').val(),
            input = $('input[type="hidden"]'),
            container = input.attr('container'),
            subtype = input.attr('subtype'),
            div = createDivElement({ class: 'input-group ' + subtype + '-' + name });
        if (name == '' || value == '') {
            $('.alert').show();
            return false;
        };
        $(container).append(div.append(createParamsLabel(subtype, name, value)));
        $('#modal-dialog').modal('hide');
    })

    $('form').submit(function() {
        var form = $(this);
        addFieldsToTheForm(form);
        var func = crichtonAjax.call(form.attr('method'), form.attr('action'), form.serialize(), 'html');
        func(crichtonAjax.replaceCallback('.main-content'));
        return false;
    });

    $('a').click(function() {
        var link = $(this);
        var url = addParametersToUrl(link.attr('href'));
        link.attr('href', url);
        var func = crichtonAjax.call('GET', url, '', 'html');
        func(crichtonAjax.replaceCallback('.main-content'));
        return false;
    });

    $('a[target]').each(function() {
        var link = $(this),
            url = link.attr('href'),
            input = link.next('input'),
            name = input.attr('name'),
            value = input.val(),
            url = 'crichton_controller_uri?url=' + url;
        var func =  crichtonAjax.call('GET', url, '', 'json');
        func(crichtonAjax.buildSelectorCallback(name, value, link));
    });
});


function addFieldsToTheForm(form) {
    $('span[param-name]').each(function() {
        var name = $(this).attr('param-name');
        var value = $(this).attr('param-value');
        var input = createInputElement({ type: 'hidden', name: name, value: value });
        input.appendTo(form);
    });
}

function addParametersToUrl(url) {
    $('span[param-name]').each(function() {
        url = updateUrl(url, $(this).attr('param-name'), $(this).attr('param-value'));
    });
    return url;
}

function createModal(title, subtype, container) {
    var modalObject = initializeModal(title);
    var hidden = createInputElement({ type: 'hidden', subtype: subtype, container: container });
    hidden.appendTo(modalObject)
    modalObject.modal('show');
}

function initializeModal(title) {
    var modalObject = $('#modal-dialog');
    $('.modal-title').text(title);
    $('.modal-body').empty();
    $('.modal-body').append(buildAlertMessage());
    $('input[subtype]').remove();
    $('.alert').hide();
    return modalObject;
}

//used to build label/input control group within bootstrap control-group element
function buildControlGroup(elementGroup) {
    var divControlGroup = createDivElement({ class: 'control-group' }),
        label = createLabelElement({ for: elementGroup }, capitalizeFirstLetter(elementGroup)),
        divControls = createDivElement({ class: 'controls' }),
        input = createInputElement({ class: 'span5 element-' + elementGroup, type: 'text', name: 'value' }),
        span = createSpanElement({ class: 'help-block hide' });
    span.appendTo(divControls);
    input.appendTo(divControls);
    label.appendTo(divControlGroup);
    divControls.appendTo(divControlGroup);
    return divControlGroup;
}

function buildAlertMessage() {
    return createDivElement({ class: 'alert alert-warning' })
        .text("Warning! Input fields can't be blank!");
}

//adds parameters key/value pair to the top of the page.
function createParamsLabel(subtype, name, value) {
    var content = createSpanElement(buildOptions(subtype, name, value), name + ' : ' + value);
    var close = createButton({ class: 'close', type: 'button' }, '&times;', function() {
        var selector = '.' + subtype + '-' + name;
        $(selector).remove();
    }).appendTo(content);
    return content;
}

//parameters key/value pair representation
function buildOptions(subtype, name, value) {
    var subtypeName = subtype + '-name',
        subtypeValue = subtype + '-value',
        options =  { class: 'label label-info input-group-addon' };
    options[subtypeName] = name;
    options[subtypeValue] = value;
    return options;
}

//used to build selector from external resource
function buildSelectorGroup(name, value, data, prompt, target) {
    var select = createSelectElement({class: 'select-item', name: name});
    $.each(data, function(index, item) {
        createOptionElement({value: item[target]}, item[prompt]).appendTo(select);
    });
    return select;
}

function createDivElement(options) {
    return createElement('<div/>', options);
}

function createLabelElement(options, text) {
    return createElement('<label/>', options).text(text);
}

function createInputElement(options, text) {
    return createElement('<input/>', options).text(text);
}

function createSpanElement(options, text) {
    return createElement('<span/>', options).text(text);
}

function createButton(options, text, clickEvent) {
    return createElement('<button/>', options).html(text).button().click(clickEvent);
}

function createSelectElement(options) {
    return createElement('<select/>', options);
}

function createOptionElement(options, text) {
    return createElement('<option/>', options).text(text);
}

function createElement(element, options) {
    return $(element, options);
}

function getSelector() {
    ($("ul[itemtype]").length > 1) ? selector = $("ul[itemtype]:gt(0)") : selector = $("ul[itemtype]")
    return selector;
}

function updateUrl(url, key, value) {
    var re = new RegExp("([?|&])" + key + "=.*?(&|$)", "i");
    separator = url.indexOf('?') !== -1 ? "&" : "?";
    if (url.match(re)) {
        return url.replace(re, '$1' + key + "=" + value + '$2');
    }
    else {
        return url + separator + key + "=" + value;
    }
}

function setValues(attribute, value, context) {
  $('select[name="' + attribute + '"]', context).each(function (index, element) {
    var option = 'option[value="' + value + '"]'
    $(option, element).attr("selected", "selected")
  });
  $('input[name="' + attribute + '"]', context).each(function (index, element) {
    if ($(this).attr('type') == 'checkbox') {
      if (value == 'true') {
        $(this).prop('checked', value)
      }
    } else {
      $(this).val(value)
    }
  });
}

function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}
