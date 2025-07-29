# Dialog Stimulus Controller

This Stimulus controller replaces the plain JavaScript dialog functionality with a more maintainable and Rails-friendly approach.

## Features

- **Automatic initialization**: No need to manually instantiate dialog objects
- **Flash message management**: Built-in support for displaying and clearing flash messages
- **Event handling**: Automatic setup and cleanup of event listeners
- **Accessibility**: Proper ARIA attributes and keyboard navigation support

## Usage

### HTML Structure

```html
<!-- Trigger button -->
<button data-dialog="my-dialog">Open Dialog</button>

<!-- Dialog container -->
<div 
  data-controller="dialog" 
  data-dialog-id-value="my-dialog"
  id="my-dialog" 
  class="dialog"
>
  <div class="dialog__content" data-dialog-target="dialog">
    
    <!-- Flash message area -->
    <div data-dialog-target="flash" id="dialog_flash"></div>
    
    <!-- Dialog header -->
    <div class="dialog__header">
      <h2>Dialog Title</h2>
      <button 
        class="button--close" 
        data-dialog-target="closeButton"
        aria-label="Close dialog"
      >
        ×
      </button>
    </div>
    
    <!-- Dialog body -->
    <div class="dialog__body">
      <p>Dialog content goes here</p>
    </div>
  </div>
</div>
```

### Controller Targets

- `dialog`: The main dialog content element that gets the 'open' class
- `flash`: The element where flash messages are displayed
- `closeButton`: The close button element

### Controller Values

- `id`: The unique identifier for the dialog (used to match trigger buttons)

### Controller Actions

- `open`: Opens the dialog and clears flash messages
- `close`: Closes the dialog
- `clearFlash`: Clears any existing flash messages
- `setFlash(message, type)`: Sets a flash message with optional type (success, error, info, warning)

### Programmatic Usage

```javascript
// Get the dialog controller instance
const dialogController = application.getControllerForElementAndIdentifier(
  document.querySelector('[data-controller="dialog"]'), 
  'dialog'
);

// Set flash messages
dialogController.setFlash('Success message!', 'success');
dialogController.setFlash('Error message!', 'error');
dialogController.setFlash('Info message!', 'info');

// Open/close dialog
dialogController.open();
dialogController.close();
```

## Migration from Plain JavaScript

### Before (Plain JS)
```javascript
const dialog = new Dialog(document.querySelector('#my-dialog'));
```

### After (Stimulus)
```html
<div data-controller="dialog" data-dialog-id-value="my-dialog">
  <!-- dialog content -->
</div>
```

The Stimulus controller automatically handles all the functionality that was previously managed by the plain JavaScript class.

## CSS Classes

The controller adds/removes the `open` class on the dialog target element. Make sure your CSS handles this class appropriately:

```css
.dialog__content {
  display: none;
}

.dialog__content.open {
  display: block;
}
``` 