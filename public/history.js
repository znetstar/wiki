'use strict';

$(function () {
	$('table.history tr').click(function () {
		let id = $(this).attr('data-article-id');
		window.document.location = `/articles/${id}`;
	});
});