/*global $*/
$('#favorite_buttons_<%= @program.id %>').html("<%= j( render partial: 'members/programs/favorite', locals: { program: @program, member: @member } ) %>");