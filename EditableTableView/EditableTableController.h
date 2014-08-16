//
//  EditableTableController.h
//  XYEdit
//
//  Created by Alfred Hanssen on 8/15/14.
//  Copyright (c) 2014 XY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Note: This class currently supports single section tableViews only

@class EditableTableController;

@protocol EditableTableControllerDelegate <NSObject>

@required

- (void)editableTableController:(EditableTableController *)controller
 willBeginMovingCellAtIndexPath:(NSIndexPath *)indexPath;

- (void)editableTableController:(EditableTableController *)controller
  movedCellWithInitialIndexPath:(NSIndexPath *)initialIndexPath
             fromAboveIndexPath:(NSIndexPath *)fromIndexPath
               toAboveIndexPath:(NSIndexPath *)toIndexPath;

- (void)editableTableController:(EditableTableController *)controller
didMoveCellFromInitialIndexPath:(NSIndexPath *)initialIndexPath
                    toIndexPath:(NSIndexPath *)toIndexPath;

@end

@interface EditableTableController : NSObject

@property (nonatomic, weak) id<EditableTableControllerDelegate> delegate;
@property (nonatomic, assign, getter = isEnabled) BOOL enabled;

- (instancetype)initWithTableView:(UITableView *)tableView;

@end
