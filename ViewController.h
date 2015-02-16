//
//  ViewController.h
//  Rahul Practice
//
//  Created by MAYUR on 15/02/15.
//  Copyright (c) 2015 MAYUR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "SKDatabase.h"

@interface ViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate,UITextFieldDelegate>
{
    
    SKDatabase *skdata;
    NSArray *ary;
    IBOutlet UITableView *objtable;
  
}




@end

