// Show the “simple” UI and reset fields
function show_simple() {
  document.querySelectorAll('.simple').forEach(el => el.style.display = '');
  document.querySelectorAll('.advanced').forEach(el => el.style.display = 'none');
  document.getElementById('simple').style.display = 'none';
  document.getElementById('advanced').style.display = '';
  
  // Set target_type to “ip” and update
  const targetSelect = document.getElementById('target_type');
  if (targetSelect) {
    targetSelect.value = 'ip';
    toggleTypes('target');
  }

  // Set src_type to “any” and update
  const srcSelect = document.getElementById('src_type');
  if (srcSelect) {
    srcSelect.value = 'any';
    toggleTypes('src');
  }

  // Select ALLOW on filter_policy
  const filterPolicy = document.getElementById('filter_policy');
  if (filterPolicy) {
    filterPolicy.value = 'ALLOW';
  }
}

// Show the “advanced” UI
function show_advanced() {
  document.querySelectorAll('.simple').forEach(el => el.style.display = 'none');
  document.querySelectorAll('.advanced').forEach(el => el.style.display = '');
  document.getElementById('advanced').style.display = 'none';
  document.getElementById('simple').style.display = '';
}

// Hide or show elements with class .filter_policy based on the policy value
function toggle_filter_policy(value) {
  document.querySelectorAll('.filter_policy').forEach(el => {
    el.style.display = (value === 'RETURN') ? 'none' : '';
  });
}

// Handler for when any .policy select changes
function policy_change() {
  toggle_filter_policy(this.value);
}

// Handler for when the target_type select changes
function target_type_change() {
  const val = this.value;
  if (val === 'ip') {
    const v = document.getElementById('policy_ip')?.value;
    toggle_filter_policy(v);
  } else if (val === 'user') {
    const v = document.getElementById('policy_user')?.value;
    toggle_filter_policy(v);
  } else if (val === 'lb') {
    const v = document.getElementById('policy_lb')?.value;
    toggle_filter_policy(v);
  } else if (val === 'map') {
    toggle_filter_policy('RETURN');
  }
}

// Enable/disable target ports fields based on protocol value
function toggle_target_ports(protoField) {
  const proto = document.getElementsByName(protoField)[0];
  if (!proto) return;

  const names = ['target_port_ip', 'target_port_user', 'target_port_lb', 'target_port_l2tp'];
  names.forEach(name => {
    const el = document.getElementsByName(name)[0];
    if (!el) return;
    if (proto.value === 'any' || proto.value === '') {
      el.value = '';
      el.disabled = true;
    } else {
      el.disabled = false;
    }
  });
}

// Wire up events once the DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('simple')?.addEventListener('click', show_simple);
  document.getElementById('advanced')?.addEventListener('click', show_advanced);
  document.querySelectorAll('.policy').forEach(el =>
    el.addEventListener('change', policy_change)
  );
  document.getElementById('target_type')?.addEventListener('change', target_type_change);

  // initialize target ports state
  toggle_target_ports('protocol');
});
