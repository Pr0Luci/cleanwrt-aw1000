'use strict';
'require view';
'require form';

/* Syncthing has no LuCI app of its own. This page is its on/off switch: the
 * init reads syncthing.syncthing.enabled and reloads when /etc/config/syncthing
 * changes, so Save & Apply starts or stops the service (same model as the other
 * opt-in services). */
return view.extend({
	render: function () {
		var m, s, o;

		m = new form.Map('syncthing', _('Syncthing'),
			_('Peer-to-peer file synchronisation between your phone, PC and this router. ' +
			  'When enabled, the Syncthing dashboard listens on the address below. ' +
			  'Open it once and set a GUI user name and password before pairing a device.'));

		s = m.section(form.NamedSection, 'syncthing', 'syncthing');
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.rmempty = false;
		o.default = '0';

		o = s.option(form.Value, 'gui_address', _('Dashboard address'),
			_('Default http://0.0.0.0:8384 (reachable from the LAN). Use http://127.0.0.1:8384 to keep it local.'));
		o.placeholder = 'http://0.0.0.0:8384';
		o.rmempty = false;

		o = s.option(form.DummyValue, '_dashboard', _('Dashboard'));
		o.rawhtml = true;
		o.cfgvalue = function () {
			var url = 'http://' + window.location.hostname + ':8384/';
			return '<a href="' + url + '" target="_blank" rel="noopener">' + url + '</a>';
		};

		return m.render();
	}
});
