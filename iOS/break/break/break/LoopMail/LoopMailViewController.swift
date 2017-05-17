//
//  LoopMailViewController.swift
//  break
//
//  Created by Saagar Jha on 1/22/16.
//  Copyright © 2016 Saagar Jha. All rights reserved.
//

import UIKit

class LoopMailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate {

	static let cellIdentifier = "LoopMail"

	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .long
		dateFormatter.timeStyle = .short
		return dateFormatter
	}()

	var schoolLoop: SchoolLoop!
	var loopMail = [SchoolLoopLoopMail]()
	var filteredLoopMail = [SchoolLoopLoopMail]()

	var destinationViewController: LoopMailMessageViewController!

	@IBOutlet weak var loopMailTableView: UITableView! {
		didSet {
			breakShared.autoresizeTableViewCells(for: loopMailTableView)
			breakShared.addRefreshControl(refreshControl, to: loopMailTableView)
			refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
		}
	}
	let refreshControl = UIRefreshControl()
	let searchController = UISearchController(searchResultsController: nil)

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		addSearchBar(from: searchController, to: loopMailTableView)
		schoolLoop = SchoolLoop.sharedInstance
		if traitCollection.forceTouchCapability == .available {
			registerForPreviewing(with: self, sourceView: loopMailTableView)
		}
		refresh(self)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		loopMail = SchoolLoop.sharedInstance.loopMail
		updateSearchResults(for: searchController)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func refresh(_ sender: Any) {
		schoolLoop.getLoopMail { (_, error) in
			DispatchQueue.main.async { [weak self] in
				guard let `self` = self else {
					return
				}
				if error == .noError {
					(UIApplication.shared.delegate as? AppDelegate)?.saveCache()
					`self`.loopMail = `self`.schoolLoop.loopMail
					`self`.updateSearchResults(for: self.searchController)
				}
				// Otherwise the refresh control dismiss animation doesn't work
				`self`.refreshControl.perform(#selector(UIRefreshControl.endRefreshing), with: nil, afterDelay: 0)
			}
		}
	}

	@IBAction func openSettings(_ sender: Any) {
		let viewController = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "settings")
		navigationController?.present(viewController, animated: true, completion: nil)
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return filteredLoopMail.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: LoopMailViewController.cellIdentifier, for: indexPath) as? LoopMailTableViewCell else {
			assertionFailure("Could not deque LoopMailTableViewCell")
			return tableView.dequeueReusableCell(withIdentifier: LoopMailViewController.cellIdentifier, for: indexPath)
		}
		let loopMail = filteredLoopMail[indexPath.row]
		cell.subjectLabel.text = loopMail.subject
		cell.senderLabel.text = loopMail.sender.name
		cell.dateLabel.text = LoopMailViewController.dateFormatter.string(from: loopMail.date)
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}

	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let replyAction = UITableViewRowAction(style: .default, title: "Reply") { [weak self] _, indexPath in
			guard let `self` = self else {
				return
			}
			guard let destinationViewController = `self`.storyboard?.instantiateViewController(withIdentifier: "loopMailCompose") as? LoopMailComposeViewController else {
				return
			}
			let selectedLoopMail = `self`.filteredLoopMail[indexPath.row]
			self.schoolLoop.getLoopMailMessage(withID: selectedLoopMail.ID) { error in
				guard error == .noError else {
					return
				}
				guard let loopMail = `self`.schoolLoop.loopMail(forID: selectedLoopMail.ID) else {
					assertionFailure("Could not get LoopMail for ID")
					return
				}
				DispatchQueue.main.async {
					destinationViewController.loopMail = loopMail
					destinationViewController.composedLoopMail = SchoolLoopComposedLoopMail(subject: "\(loopMail.subject)", message: loopMail.message, to: [loopMail.sender], cc: [])
					`self`.navigationController?.pushViewController(destinationViewController, animated: true)
				}
			}
		}
		replyAction.backgroundColor = view.tintColor
		return [replyAction]
	}

	func updateSearchResults(for searchController: UISearchController) {
		let filter = searchController.searchBar.text?.lowercased() ?? ""
		if filter != "" {
			filteredLoopMail.removeAll()
			filteredLoopMail = loopMail.filter { loopMail in
				return loopMail.subject.lowercased().contains(filter) || loopMail.sender.name.lowercased().contains(filter)
			}
		} else {
			filteredLoopMail = loopMail
		}
		DispatchQueue.main.async { [unowned self] in
			self.loopMailTableView.reloadData()
		}
	}

	// MARK: - Navigation

	func openLoopMailMessage(for loopMail: SchoolLoopLoopMail) {
		guard let loopMailMessageViewController = storyboard?.instantiateViewController(withIdentifier: "loopMailMessage") as? LoopMailMessageViewController else {
			assertionFailure("Could not create LoopMailMessageViewController")
			return
		}
		loopMailMessageViewController.ID = loopMail.ID
		navigationController?.pushViewController(loopMailMessageViewController, animated: true)
	}

	func openLoopMailCompose(for loopMail: SchoolLoopLoopMail) {
		guard let loopMailComposeViewController = self.storyboard?.instantiateViewController(withIdentifier: "loopMailCompose") as? LoopMailComposeViewController else {
			assertionFailure("Could not create LoopMailComposeViewController")
			return
		}
		(schoolLoop ?? SchoolLoop.sharedInstance).getLoopMailMessage(withID: loopMail.ID) { [weak self] error in
			guard let `self` = self else {
				return
			}
			guard error == .noError else {
				return
			}
			guard let loopMail = self.schoolLoop.loopMail(forID: loopMail.ID) else {
				assertionFailure("Could not get LoopMail for ID")
				return
			}
			DispatchQueue.main.async {
				loopMailComposeViewController.loopMail = loopMail
				loopMailComposeViewController.composedLoopMail = SchoolLoopComposedLoopMail(subject: "\(loopMail.subject)", message: loopMail.message, to: [loopMail.sender], cc: [])
				`self`.navigationController?.pushViewController(loopMailComposeViewController, animated: true)
			}
		}
	}

	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let indexPath = loopMailTableView.indexPathForRow(at: location),
			let cell = loopMailTableView.cellForRow(at: indexPath) else {
				return nil
		}
		guard let destinationViewController = storyboard?.instantiateViewController(withIdentifier: "loopMailMessage") as? LoopMailMessageViewController else {
			return nil
		}
		let selectedLoopMail = filteredLoopMail[indexPath.row]
		destinationViewController.ID = selectedLoopMail.ID
		// Give it a placeholder LoopMail while it loads its own, for any
		// preview actions
		destinationViewController.loopMail = selectedLoopMail
		destinationViewController.parentNavigationController = navigationController
		destinationViewController.preferredContentSize = CGSize(width: 0, height: 0)
		previewingContext.sourceRect = cell.frame
		return destinationViewController
	}

	func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		navigationController?.pushViewController(viewControllerToCommit, animated: true)
	}

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		guard let destinationViewController = segue.destination as? LoopMailMessageViewController,
			let cell = sender as? LoopMailTableViewCell,
			let indexPath = loopMailTableView.indexPath(for: cell) else {
				return
		}
		let selectedLoopMail = filteredLoopMail[indexPath.row]
		destinationViewController.ID = selectedLoopMail.ID
		// Give it a placeholder LoopMail while it loads its own, for any
		// preview actions
		destinationViewController.loopMail = selectedLoopMail
		self.destinationViewController = destinationViewController
		destinationViewController.parentNavigationController = navigationController
	}
}
