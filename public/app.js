'use strict';
$(document).on('ready', function () {
	$(document).on({
		keyup: function (event) {
			if (event.which === 13) {
				let value = $('.searchbar').val();
				window.document.location = `/search/${value}`;
			}
		}
	}, '.searchbar');
});