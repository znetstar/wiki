'use strict';

var $ = window.jQuery;
function sync_changes () {
	var markdown = window.simplemde.value();
	$.ajax({
		method: "put",
		url: `/article/${$('[name="article_id"]').attr('content')}`,
		data: {
			title: $('input[name="title"]').val(),
			body: markdown
		}
	})
	.done(function( data ) {
		try {
			var resp = JSON.parse(data);

			$('.article-header h1').html(resp.title);
			$('title').html(`${resp.title} - ${$('meta[name="title"]').attr('content')}`);
			$('.article-body').html(resp.body);

			$('a[rel="author"]')
				.attr('href', `/authors/${resp.author.id}`)
				.text(`${resp.author.fname} ${resp.author.lname}`);

			resp.datetime = new Date(resp.datetime);
			$('.article-byline time').attr('datetime', strftime('%F', resp.datetime))
			$('.article-byline time').text(strftime('%m/%d/%Y at %I:%M%p', resp.datetime))
		} catch (e) {

		}
	});
}

$(function () {
	$('input[name="title"]')
		.keyup(function () {
			let title = $(this).val();
			let site_title = $('meta[name="title"]').attr('content');
			$('title').html(`${title} - ${site_title}`);

		})
		.change(function () {
			sync_changes();
		});

		var simplemde = window.simplemde = new SimpleMDE({ 
			element: $("textarea.edit")[0],
			autoDownloadFontAwesome: false,
			autosave: {
				enabled: true,
				delay: 10000,
				uniqueId: $('[name="article_id"]').attr('content')
			}
		});

		simplemde._autosave = simplemde.autosave;
		simplemde.autosave = function () {
			sync_changes();
			simplemde._autosave.apply(this, arguments);
		}

		simplemde.codemirror.on('blur', function () {
			sync_changes();
		});

		$('.delete-article').click(function (event) {
			$.ajax({
				method: "delete",
				url: `/article/${$('[name="article_id"]').attr('content')}`
			})
			.done(function (msg) {
				window.document.location = '/';
			});
		});

		load_markdown();
});