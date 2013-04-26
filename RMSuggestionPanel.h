//
//  RMSuggestionTextfield.h
//
//  Created by Raffael Hannemann on 27.01.13.
//  Copyright (c) 2013 raffael.me. All rights reserved.
//  BSD License

#import <Foundation/Foundation.h>

/** The RMSuggestionPanel is a view that lets the user chose one single of a set of items coming from a datasource. The delegate will be notified once the user confirms his selection.
 To make use of a RMSuggestionPanel, instantiate a NSView in the Interface Builder and set its class to RMSuggestionPanel. Define a datasource and a delegate by binding the objects in the Interface Builder or manually by code. */

@class RMSuggestionPanel;

#pragma mark RMSuggestionPanelDatasource protocol

/** The RMSuggestionPanelDatasource protocol defines the methods that a datasource of RMSuggestionPanel should implement. The representedObjectOfItemIndex:ofSuggestionPanel:; method is is optional and can be used to assign an object to the respective list item. It can later be retrieved by the delegate by asking the RMSuggestionPanel for the item for the selected identifier and its representedObject property. */
@protocol RMSuggestionPanelDatasource <NSObject>
- (int) numberOfItemsOfSuggestionPanel:(RMSuggestionPanel *) textfield;
- (NSString *) identifierOfItemIndex: (int) index ofSuggestionPanel:(RMSuggestionPanel *) textfield;
- (NSString *) titleOfItemIndex: (int) index ofSuggestionPanel:(RMSuggestionPanel *) textfield;
- (NSString *) informationTextOfItemIndex: (int) index ofSuggestionPanel:(RMSuggestionPanel *) textfield;
- (NSImage *) imageOfItemIndex: (int) index ofSuggestionPanel:(RMSuggestionPanel *) textfield;
@optional
- (id) representedObjectOfItemIndex: (int) index ofSuggestionPanel:(RMSuggestionPanel *) textfield;
@end

#pragma mark -
#pragma mark RMSuggestionPanelDelegate protocol

/** The RMSuggestionPanelDelegate protocol defines the methods that a delegate of RMSuggestionPanel should implement. Only suggestionPanel:userDidConfirmIdentifier:; is required. */
@protocol RMSuggestionPanelDelegate <NSObject>
/** The delegate will be notified once the user has chosen a certain list item by either hitting Enter or clicking once or twice with the mouse, depending on the RMSuggestionPanel configuration. The selected item can be retrieved by the currentlyHighlightedItem property. */
- (void) suggestionPanel: (RMSuggestionPanel *) textfield userDidConfirmIdentifier: (NSString *) identifier;
@optional
/** The delegate will be notified once the user selected a different list item by either clicking with the mouse once or using the up and down keys. Remember this is not the actual user chosing operation. */
- (void) suggestionPanel: (RMSuggestionPanel *) textfield userDidSelectIdentifier: (NSString *) identifier;
/** If the shrinkAutomatically property is set, the whole NSView object of the RMSuggestionPanel will decrease its size once the list items are filtered. Then, the delegate will be informed to be able to adapt the containing view element, if required. */
- (void) suggestionPanel: (RMSuggestionPanel *) textfield didChangeHeight: (int) newHeight;
//TODO: implement:
- (void) userDidUnselectItemsForSuggestionPanel: (RMSuggestionPanel *) textfield;
- (void) suggestionPanel:(RMSuggestionPanel *)textfield userDidSecondaryClickOnItemIdentifier: (NSString *) identifier withEvent:(NSEvent *) theEvent;
@end


#pragma mark -
#pragma mark RMSuggestionListViewItem class

/** Simple data container to hold a list item's data, no modification methods. */
@interface RMSuggestionListViewItem : NSObject
@property (retain) NSString *identifier;
@property (retain) NSString *title;
@property (retain) NSString *information;
@property (retain) NSImage *image;
@property (retain) id representedObject;
@property (assign) BOOL isHighlighted;
@property (assign) BOOL isHidden;
@property (assign) int index;
@end

#pragma mark -
#pragma mark RMSuggestionListView class

/** The List View shows the List Items of the Suggestion Panel. */
@interface RMSuggestionListView : NSView {
	NSPoint _mouseClick;
	int _rowHeight; // will be read from parent in every drawRect:; call
	RMSuggestionPanel *parent;
	RMSuggestionListViewItem *lastUserSelectedItem;
	BOOL hasSyntheticallyDeterminedSelectedItem;
}
- (void) setParent: (RMSuggestionPanel *) parent;
- (void) selectNextItem;
- (void) selectPreceedingItem;
- (void) resetMouseClick;
- (void) filterDidChange;
@end

#pragma mark -
#pragma mark RMSuggestionPanel class

/** The RMSuggestionPanel is a view that lets the user chose one single of a set of items coming from a datasource. The delegate will be notified once the user confirms his selection. */
@interface RMSuggestionPanel : NSView <NSControlTextEditingDelegate,NSTextFieldDelegate> {
	BOOL manualSensedResponder;
}
@property (retain,readonly) NSSearchField *searchField;
@property (retain,readonly) NSScrollView *scrollView;
@property (retain,readonly) RMSuggestionListView *listView;
@property (retain,nonatomic) IBOutlet NSResponder *sensedResponder; // The blue highlight will be dimmed based on whether the sensedResponder is the key window. By default, this is the frame's window, but in embedded in NSPopovers, the sensed responder might be set to the NSPopover's parent window.

@property (retain) IBOutlet id<RMSuggestionPanelDatasource> datasource; // The datasource for this panel.
@property (retain) IBOutlet id<RMSuggestionPanelDelegate> delegate; // The delegate for this panel.

/** The listItems is the set of RMSuggestionListViewItems build by reading from the datasource. The filtered list items set is the current set of items that match the user's filter setting. */
@property (retain) NSArray *listItems;
@property (retain) NSMutableArray *filteredListItems;

/** The index represents the current user selection of the panel respecting the order of the datasource. */
@property (assign,nonatomic) int highlightedRowIndex;
@property (retain) RMSuggestionListViewItem *currentlyHighlightedItem;

/** The filter needle the user set to filter the set of items. Custom Setter implemented. */
@property (retain,nonatomic) NSString *currentFilter;


/* Puplic options. */
@property (assign) int rowHeight; // The height of the list items.
@property (assign) BOOL	 confirmWithDoubleclick; // User has to click twice on list item to confirm selection. Default is YES.
@property (assign) float selectionBoxRadius; // Box radius of selection box. Default is 0, choose 4 for NSPopovers.
@property (assign) BOOL	 drawBackground; // Uses light grey to draw background of element.
@property (assign) BOOL	 reactOnKeyWindowChange; // Dims the blue selection box if window is not key window.
@property (assign) BOOL	 shrinkAutomatically; // Shrinks the size of the panel with decreasing item number automatically and informs the delegate.
@property (retain, nonatomic) NSString *placeholderString; // The NSSearchfield placeholder text, by default "Search".
@property (assign) int	 defaultScrollViewHeight; // The default height of the scroll view. Will be determined automatically.
typedef void (^RMSuggestionPanelRowDrawingBlock)(RMSuggestionListViewItem *item, BOOL drawsAsMainWindow, BOOL isSelectedRow, NSRect rowRect, int rowIndex, int itemIndex);
@property (assign) RMSuggestionPanelRowDrawingBlock rowOverlayDrawingBlock; // Will draw over every list item rect.
@property (assign) int searchFieldMarginLeft;
@property (assign) int searchFieldMarginRight;
@property (assign) int searchFieldMarginBottom;
@property (assign, nonatomic) BOOL showSearchField;
@property (retain) NSColor *alternatingColor; // If set, every second row will have a painted background color. Can contain transparency.

- (void) reloadData;
- (void) reset;
- (void) scrollToTop;
- (RMSuggestionListViewItem *) itemForIdentifier: (NSString *) identifier;
- (void) confirmSelection: (RMSuggestionListViewItem *) item;
- (void) setSelectionBoxRadius: (float) radius;

@end

