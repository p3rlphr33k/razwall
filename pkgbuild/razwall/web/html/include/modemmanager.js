// Current/previous MM settings
var MM_PREDEFINED_APN = null;
var MM_PREDEFINED_USERNAME = null;
var MM_PREDEFINED_PASSWORD = null;
var MM_MODEM_FOUND = null;
var MM_PROVIDERS = {};
var MM_COUNTRIES = {};

function mm_is_uplinkeditor() {
  return (typeof $("#uplinkmanualdns").val() != "undefined");
}

function refresh_mm_modems() {
    var select = $("select[name=MM_MODEM]");
    var selected_id = $("input[name=MM_MODEM]").val();
    if (typeof selected_id === "undefined") {
      selected_id = "";
    }
    var current_modem_found = false;
    $("#mm_refresh_icon").attr("src", "/images/indicator.gif")
    select.removeOption("");
    select.removeOption(/./);
    $.ajax({
        url: "mm-modems-json.cgi",
        dataType: "json",
    }).done(function(data) {
      MM_MODEM_FOUND = data;
      $("#mm_refresh_icon").attr("src", "/images/reconnect.png")
      $.each(data, function(index, value) {
        if (selected_id === "") {
          selected_id = value.identifier;
        }
        selected = (selected_id === value.identifier);
        if (selected) {
            current_modem_found = true;
        }
        var caption = value.manufacturer + " " + value.model + " (" + value.identifier + ")";
        select.addOption(value.identifier, caption, selected);
      });
      var disabled = false;
      if (current_modem_found === false) {
          if (selected_id === "") {
            var caption = "No modem found";
            var disabled = true;
          } else {
            var caption = "Unknown/Not Found (" + selected_id + ")";
          }
          select.addOption(selected_id, caption, true);
      }
      select.prop("disabled", disabled);
      select.sortOptions();
      select.trigger("change");
    });
}

function select_modem(modem_id) {
  var selected_modem = null;
  $.each(MM_MODEM_FOUND, function(index, modem) {
    if (modem_id === modem.identifier) {
      selected_modem = modem;
    }
  });

  if (selected_modem === null) {
    var modem_identifier = $("input[name=MM_MODEM]").val();
    if (modem_identifier === "") {
      selected_modem = {
        technology: "",
        identifier: "",
        status: "Modem not found",
      };
    } else {
      selected_modem = { 
        technology: $("input[name=MM_MODEM_TYPE]").val(),
        identifier: modem_identifier,
        status:"Modem not found"
      };
    }
  }

  if (selected_modem.technology === "GSM") {
    technology = "GSM/UMTS/HDSPA/LTE"
  } else if (selected_modem.technology === "CDMA") {
    technology = "CDMA/EVDO"
  } else if (selected_modem.technology === "POTS") {
    technology = "Analog Modem (POTS)"
  } else {
    technology = "";
  }

  $("#mm_modem_info_type").text(technology);
  $("#mm_modem_info_id").text(selected_modem.identifier);
  $("#mm_modem_info_status").text(selected_modem.status);


  $("input[name=MM_MODEM_TYPE]").attr("value", selected_modem.technology);
  $("input[name=MM_MODEM_TYPE]").trigger("change");

}

  // $("#uplinkipsactive").show();
  // if (ips == true) {
  //     $("#uplinkips").show();
  // }

function mm_uplinkeditor_show_providers_country(technology) {
  var dns = $("input[name=DNS]").get(0).checked;
  $("#uplinkdns").show();
  if (dns == true) {
      $("#uplinkmanualdns").show();
  }
  $("#uplinkuserpass").show();
  $("#uplinkauth").show();
  if (technology == "GSM") {
    $("#uplinkapn").show();
  } else if (technology == "CDMA") {
    $("#uplinkapn").hide();
  } else if (technology == "POTS") {
    $("#uplinkapn").hide();
  } else {
    $("#uplinkapn").hide();
  }
  mm_show_providers_country(technology);
}

function mm_show_providers_country(technology) {
  $("select[name=MM_PROVIDER_COUNTRY]").removeOption(/./);
  $("select[name=MM_PROVIDER_PROVIDER]").removeOption(/./);
  $("select[name=MM_PROVIDER_APN]").removeOption(/./);

  var technology = technology.toLowerCase();
  var selected_id = $("input[name=MM_PROVIDER_COUNTRY]").val();
  if (typeof selected_id === "undefined") {
    selected_id = "";
  }
  var select = $("select[name=MM_PROVIDER_COUNTRY]");
  data = MM_PROVIDERS[technology];
  $.when(
    $.getJSON("mm-providers-json.cgi", function(d) {MM_PROVIDERS = d}),
    $.getJSON("mm-countries-json.cgi", function(d) {MM_COUNTRIES = d})
  ).then(function() {
    data = MM_PROVIDERS[technology];
    select.removeOption(/./);
    $.each(data, function(key, country) {
      country_name = MM_COUNTRIES[key.toUpperCase()]
      select.addOption(key, country_name, (selected_id === key));
    });
    select.sortOptions();
    if (selected_id === "") {
      select.children()[0].selected = true;
    }
    select.trigger("change");
  });
}


function mm_changed_country(technology, country) {
  var technology_lower = technology.toLowerCase();
  var data = MM_PROVIDERS[technology_lower][country];
  var selected_id = $("input[name=MM_PROVIDER_PROVIDER]").val();
  if (typeof selected_id === "undefined") {
    selected_id = "";
  }
  var select = $("select[name=MM_PROVIDER_PROVIDER]");
  select.removeOption(/./);
  $.each(data, function(key, provider) {
    if (key != "__name__") {
      select.addOption(key, key, (selected_id === key));
    }
  });
  if ((country === $("input[name=MM_PROVIDER_COUNTRY]").val()) && (selected_id === "__CUSTOM__")) {
      select.addOption("__CUSTOM__", "Custom...", true);
  }
  select.sortOptions();
  if (selected_id === "") {
    select.children()[0].selected = true;
  }
  select.trigger("change");
}

function mm_selected_provider(data) {
  $("select[name=MM_PROVIDER_PROVIDER]").removeOption("__CUSTOM__");
  $("select[name=MM_PROVIDER_APN]").removeOption("__CUSTOM__");

  $("input[name=APN]").attr("value", data.apn);
  MM_PREDEFINED_APN = data.apn;

  $("input[name=USERNAME]").attr("value", data.username);
  MM_PREDEFINED_USERNAME = data.username;

  $("input[name=PASSWORD]").attr("value", data.password);
  MM_PREDEFINED_PASSWORD = data.password;

  if (mm_is_uplinkeditor() === true) {
    mm_uplinkeditor_select_auth(data.authentication);
    mm_uplinkeditor_select_dns(data.dns);
  } else {
    mm_netwizard_select_auth(data.authentication);
    mm_netwiz_select_dns(data.dns);
  }

}

function mm_changed_provider(technology, country, provider_name) {
  var technology_lower = technology.toLowerCase();
  if (technology == "GSM") {
    $("#uplink_mm_apn").show();
    if (provider_name == "__CUSTOM__") {
      data = {};
    } else {
      var data = MM_PROVIDERS[technology_lower][country][provider_name];
    }    
    var selected_id = $("input[name=MM_PROVIDER_APN]").val();
    if (typeof selected_id === "undefined") {
      selected_id = "";
    }
    var select = $("select[name=MM_PROVIDER_APN]");
    select.removeOption(/./);
    $.each(data, function(key, value) {
      select.addOption(key, value.name, (selected_id === key));
    });
    
    if ((country === $("input[name=MM_PROVIDER_COUNTRY]").val()) && (provider_name === "__CUSTOM__") && (selected_id === "__CUSTOM__")) {
        select.addOption("__CUSTOM__", "Custom...", true);
    }
    select.sortOptions();
    if (selected_id === "") {
      select.children()[0].selected = true;
    }
    select.trigger("change");
  } else if (technology == "CDMA") {
    $("#uplink_mm_apn").hide();
    if (provider_name == "__CUSTOM__") {
      data = {};
    } else {
      var data = MM_PROVIDERS[technology_lower][country][provider_name][0];
    }
    mm_selected_provider(data);
  } else if (technology == "POTS") {

  }
}

function mm_uplinkeditor_select_auth(auth) {
  var select_auth = "pap-or-chap";
  if (auth == "pap") {
    select_auth = "pap";
  } else if (auth == "chap") {
    select_auth = "chap";
  }
  $("select[name=AUTH]").selectOptions(select_auth);
}

function mm_netwizard_select_auth(auth) {
  var select_auth = "0";
  if (auth == "pap") {
    select_auth = "1";
  } else if (auth == "chap") {
    select_auth = "2";
  }
  $("select[name=AUTH_N]").selectOptions(select_auth);
}

function mm_netwiz_select_dns(dns) {
  if (dns) {
    $("input[name=DNS_N][value=0]").prop("checked", false);
    $("input[name=DNS_N][value=1]").prop("checked", true);
    $("input[name=DNS1]").attr("value", dns[0]);
    $("input[name=DNS2]").attr("value", dns[1]);
  } else {
    $("input[name=DNS_N][value=0]").prop("checked", true);
    $("input[name=DNS_N][value=1]").prop("checked", false);
    $("input[name=DNS1]").attr("value", "");
    $("input[name=DNS2]").attr("value", "");
  }
}

function mm_uplinkeditor_select_dns(dns) {
  if (dns) {
    $("input.form[name=DNS]").prop("checked", true);
    $("input[name=DNS1]").attr("value", dns[0]);
    $("input[name=DNS2]").attr("value", dns[1]);
    $("#uplinkmanualdns").show();
  } else {
    $("input.form[name=DNS]").prop("checked", false);
    $("input[name=DNS1]").attr("value", "");
    $("input[name=DNS2]").attr("value", "");
    $("#uplinkmanualdns").hide();
  }
}

function mm_changed_apn(technology, country, provider_name, apn_url) {
  var technology_lower = technology.toLowerCase();
  if (apn_url === "__CUSTOM__") {
      return;
  }
  var data = MM_PROVIDERS[technology_lower][country][provider_name][apn_url];
  mm_selected_provider(data);

}

function mm_select_custom_provider() {
    $("select[name=MM_PROVIDER_PROVIDER]").addOption("__CUSTOM__", "Custom...", true);
    $("select[name=MM_PROVIDER_APN]").removeOption(/./);
    $("select[name=MM_PROVIDER_APN]").addOption("__CUSTOM__", "Custom...", true);
}

function mm_check_custom_provider() {
  var settings = {
    apn: $("select[name=MM_PROVIDER_APN]"),
    username: $("select[name=MM_PROVIDER_USERNAME]"),
    password: $("select[name=MM_PROVIDER_PASSWORD]")
  };
  var predefined_settings = {
    apn: MM_PREDEFINED_APN,
    username: MM_PREDEFINED_USERNAME,
    username: MM_PREDEFINED_PASSWORD,
  };
  if (settings != predefined_settings) {
    mm_select_custom_provider();
  }
}


// Handlers
$(document).ready(function() {
  $("select[name=MM_MODEM]").change(function() { 
    select_modem($(this).val()); 
  });

  $("select[name=MM_PROVIDER_COUNTRY]").change(function() { 
    mm_changed_country(
      $("input[name=MM_MODEM_TYPE]").val(),
      $(this).val()
    );
  });

  $("select[name=MM_PROVIDER_PROVIDER]").change(function() {
    mm_changed_provider(
      $("input[name=MM_MODEM_TYPE]").val(),
      $("select[name=MM_PROVIDER_COUNTRY]").val(),
      $(this).val()
    ); 
  });

  $("select[name=MM_PROVIDER_APN]").change(function() {
    mm_changed_apn(
      $("input[name=MM_MODEM_TYPE]").val(),
      $("select[name=MM_PROVIDER_COUNTRY]").val(),
      $("select[name=MM_PROVIDER_PROVIDER]").val(),
      $(this).val()
    );
  });

  $("input[name=APN]").keyup(function() { mm_check_custom_provider(); });
  $("input[name=USERNAME]").keyup(function() { mm_check_custom_provider(); });
  $("input[name=PASSWORD]").keyup(function() { mm_check_custom_provider(); });

  $("input[name=MM_MODEM_TYPE]").change(function() {
    if (mm_is_uplinkeditor() === true) {
      mm_uplinkeditor_show_providers_country($(this).val()); 
    }
  });

  $("#refresh_mm_button").click(function() {
    refresh_mm_modems();
  })

  substep = $("input[name=substep]").val();
  if (substep == "1") {
    refresh_mm_modems();
  } else if (substep == "2") {
    mm_show_providers_country($("input[name=MM_MODEM_TYPE]").val());
  }
});