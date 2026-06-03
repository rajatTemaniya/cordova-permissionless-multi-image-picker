var exec = require('cordova/exec');

var PermissionlessMultiImagePicker = {
  /**
   * RajatTemaniya
   * Pick one or more images using the native permissionless photo picker.
   * Always returns an array of file:// URIs — no permissions required.
   *
   * @param {Function} success  - called with string[] of file:// URIs
   * @param {Function} error    - called with error string
   * @param {Object}   options
   * @param {number}   options.maxImages - max selectable (0 = unlimited, default)
   */
  pickImages: function (success, error, options) {
    var maxImages = (options && options.maxImages) ? options.maxImages : 0;
    exec(success, error, 'PermissionlessMultiImagePicker', 'pickImages', [maxImages]);
  }
};

module.exports = PermissionlessMultiImagePicker;