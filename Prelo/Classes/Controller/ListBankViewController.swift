//
//  ListBankViewController.swift
//  Prelo
//
//  Created by Prelo on 6/13/17.
//  Copyright © 2017 PT Kleo Appara Indonesia. All rights reserved.
//

class ListBankViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    var bank = ["BNI", "BRI", "Mandiri"]
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super .viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bank.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bankCell", for: indexPath)
        
        cell.textLabel?.text = bank[indexPath.row]
        
        return cell
    }
    
}

class BankCell : UITableViewCell
{
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var lblPicker: UILabel!
    
    func adapt(_ title : String) {
 
        self.lblText.text = title
    }
}

