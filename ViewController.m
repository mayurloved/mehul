//
//  ViewController.m
//  Rahul Practice
//
//  Created by MAYUR on 15/02/15.
//  Copyright (c) 2015 MAYUR. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

{
    UITextField *userNameTextField;
    UITextField *passwordTextField;
    UITextField *Phn;
    UIAlertView *alert, *alert1;
    NSString *selectedindex;
}

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    

    skdata = [[SKDatabase alloc]initWithFile:@"Scheduler.sqlite"];
    
    //UIBarButtonItem *add = [[UIBarButtonItem alloc]initWithTitle:@"add" style:UIBarButtonItemStyleDone target:self action:@selector(openalert)];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(openalert)];
    self.navigationItem.rightBarButtonItem = rightButton;

    
    [self.navigationController.navigationItem setRightBarButtonItem:rightButton];
    
    // Do any additional setup after loading the view, typically from a nib.
    
}

-(void)openalert
{
    
    alert = [[UIAlertView alloc]initWithTitle:@"Add" message:@"Please add" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    
    UITextField * alertTextField1 = [alert textFieldAtIndex:0];
    alertTextField1.keyboardType = UIKeyboardTypeDefault;
    alertTextField1.placeholder = @"Value 1";
    
    UITextField * alertTextField2 = [alert textFieldAtIndex:1];
    alertTextField2.keyboardType = UIKeyboardTypeDefault;
    alertTextField2.placeholder = @"Value 2";
    [[alert textFieldAtIndex:1] setSecureTextEntry:NO];

    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    NSString *catid = [NSString stringWithFormat:@"%@",[alertView textFieldAtIndex:0].text];
    NSString *catname = [NSString stringWithFormat:@"%@",[alertView textFieldAtIndex:1].text];
 
    if (alertView.tag==1)
    {
        
         NSDictionary *dict1 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:catid, @"Name",catname, @"City", nil];
       
        
        
    }
    else
    {
        
        if (buttonIndex==1)
        {
            
            NSDictionary *dict = [[NSMutableDictionary alloc]initWithObjectsAndKeys:catid, @"Name",catname, @"City", nil];
            
            [skdata insertDictionary:dict forTable:@"Employee"];
            
            
        }
    }
        
      
    [self displaydata];
    [objtable reloadData];
        
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    
    return ary.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    static NSString *CellIdentifier = @"DetailCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                      reuseIdentifier:CellIdentifier];
    
    }
    
    
    cell.textLabel.text=[[ary valueForKey:@"Name"]objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;{
    
    
    
    alert1 = [[UIAlertView alloc]initWithTitle:@"Edit" message:@"Please Edit" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
    
    alert1.tag=1;
    
    alert1.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    
    UITextField * alertTextField1 = [alert1 textFieldAtIndex:0];
    alertTextField1.text=[[ary valueForKey:@"Name"]objectAtIndex:indexPath.row];
    alertTextField1.keyboardType = UIKeyboardTypeDefault;
    alertTextField1.placeholder = @"Value 1";
    
    UITextField * alertTextField2 = [alert1 textFieldAtIndex:1];
    alertTextField2.text=[[ary valueForKey:@"City"]objectAtIndex:indexPath.row];
    alertTextField2.keyboardType = UIKeyboardTypeDefault;
    alertTextField2.placeholder = @"Value 2";
    [[alert1 textFieldAtIndex:1] setSecureTextEntry:NO];
    
   selectedindex = @"Select ID from Employee";
    NSLog(@"%@",selectedindex);
    [alert1 show];

}

-(void)viewWillAppear:(BOOL)animated{
    
    ary = [[NSArray alloc]init];
    
    [self displaydata];
    
    
}
-(void)displaydata{
    
    
    ary = [skdata lookupAllForSQL:@"Select * from Employee"];
  
}
@end
