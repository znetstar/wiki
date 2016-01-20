'use strict';

var $ = window.jQuery;
function sync_changes () {
	var markdown = window.simplemde.value();
	var tags = Array.from($.unique($('.edit-tags .tag').map(function () { return $(this).text(); }))).filter(Boolean).filter((s) => s !== '');
	
	$.ajax({
		method: "put",
		url: `/article/${$('[name="article_id"]').attr('content')}`,
		data: {
			title: $('input[name="title"]').val(),
			body: markdown,
			tags: tags.join(',')
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

			$('.edit-tags .tag').remove()
			$('.tags .tag').remove()
			resp.tags.forEach((tag) => $(`<li class="tag"><a href="/tag/${tag}">${tag}</a></li>`).insertAfter($('.edit-tags .static').first()))
			resp.tags.forEach((tag) => $(`<li class="tag"><a href="/tag/${tag}">${tag}</a></li>`).insertAfter($('.tags .static').first()))
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
			simplemde._autosave.apply(this, arguments);
		}

		simplemde.codemirror.on('blur', sync_changes);
		simplemde.codemirror.on('focus', sync_changes);

		$('.delete-article').click(function (event) {
			$.ajax({
				method: "delete",
				url: `/articles/${$('[name="article_id"]').attr('content')}`
			})
			.done(function (msg) {
				window.document.location = '/';
			});
		});

		$('.view-article').click(function () {
			window.document.location = `/articles/${$('[name="article_id"]').attr('content')}`;
		});

		$('.edit-tags .new-tag').keyup(function (e) {
			if (e.which === 13) {
				let tag = $(this).val();
				$(this).val('');
				$(`<li class="tag"><a href="/tag/${tag}">${tag}</a></li>`).insertBefore($(this));
				sync_changes();
				return false;
			}
		});

		$(document).on({
			click: function () {
				$(this).parent().remove();
				sync_changes();
				return false;
			}
		}, '.edit-tags li.tag a');

		load_markdown();
});
