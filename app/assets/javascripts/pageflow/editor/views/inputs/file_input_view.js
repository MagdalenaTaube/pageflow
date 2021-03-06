/*global editor*/

pageflow.FileInputView = Backbone.Marionette.ItemView.extend({
  mixins: [pageflow.inputView],

  template: 'templates/inputs/file_input',
  className: 'file_input',

  ui: {
    fileName: '.file_name',
    thumbnail: '.file_thumbnail',
    editPositioningButton: '.edit_positioning',
    unsetButton: '.unset'
  },

  events: {
    'click .choose': function() {
      editor.navigate(
        '/files/' + this.options.collection.name +'?page=' + this.model.page.id + '&attribute=' + this.options.propertyName,
        {trigger: true}
      );
      return false;
    },

    'click .unset': function() {
      this.model.unsetReference(this.options.propertyName);
      return false;
    },

    'click. .edit_positioning': function() {
      pageflow.ImagePositioningView.open({
        model: this.model,
        propertyName: this.options.propertyName
      });
      return false;
    }
  },

  initialize: function() {
    this.options = _.extend({
      imagePositioning: true
    }, this.options);
  },

  onRender: function() {
    this.update();
    this.listenTo(this.model, 'change:' + this.options.propertyName, this.update);
  },

  update: function() {
    var file = this._getFile();

    this.ui.fileName.text(file ? file.get('file_name') : '(Kein)');
    this.ui.unsetButton.toggle(!!file);
    this.ui.editPositioningButton.toggle(this.options.imagePositioning && !!file && file.isPositionable());

    this.subview(new pageflow.FileThumbnailView({
      el: this.ui.thumbnail,
      model: file
    }));
  },

  _getFile: function() {
    return this.model.getReference(this.options.propertyName, this.options.collection);
  }
});