//
//  ProductsVC.swift
//  TheDemo
//
//  Created by Mahmoud Mohammed on 5/18/19.
//  Copyright © 2019 TheD. All rights reserved.
//

import Alamofire
import UIKit

/// This controller is responsible to show list of products
class ProductsVC: UIViewController {

  // MARK: - Properties
  let cellID = "cellID"
  var products: [Product] = []
  let refresher = UIRefreshControl()
  var activeRequest: DataRequest?
  var disconnected = false

  // MARK: - IBOutlets
  @IBOutlet private weak var collectionView: UICollectionView!
  @IBOutlet private weak var noInternetBottomConstraint: NSLayoutConstraint!
  @IBOutlet private weak var internetBottomConstraint: NSLayoutConstraint!

  // MARK: - Lifecycle Methods
  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    loadData()
    addObservers()
  }

  // remove observers from memory
  deinit {
    removeObservers()
  }

  // MARK: - Helpers Methods
  private func setupViews() {
    title = "the D.emo"
    let producCell = UINib(nibName: "ProductCell", bundle: nil)
    collectionView.register(producCell, forCellWithReuseIdentifier: cellID)
    collectionView.delegate = self
    collectionView.dataSource = self
    refresher.addTarget(self, action: #selector(loadData), for: .valueChanged)
    refresher.tintColor = Colors.accent.color
    collectionView.refreshControl = refresher
    collectionView.contentInset = UIEdgeInsets(top: 23, left: 10, bottom: 10, right: 10)
    if let layout = collectionView?.collectionViewLayout as? PinterestLayout {
      layout.delegate = self
    }
  }

  // load products data
  @objc
  private func loadData() {
    collectionView.refreshControl?.beginRefreshing()
    activeRequest?.cancel()
    activeRequest = AF.request(APIRouter.getProducts(forceLoad: isConnected))
      .responseDecodable { [unowned self] (response: DataResponse<ProductResponse>) in
        defer { self.collectionView.refreshControl?.endRefreshing() }
        switch response.result {
          case .failure(let err):
            print(err)
          case .success(let model):
            self.products = model.data
            self.collectionView.reloadData()
        }
      }
  }

  // Notification observers to handle networking
  private func addObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(reachable), name: .reachable, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(notReachable), name: .notReachable, object: nil)
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: .notReachable, object: nil)
    NotificationCenter.default.removeObserver(self, name: .reachable, object: nil)
  }

  // To hide the connected view
  private func animateConnectedViewDown() {
    UIView.animate(withDuration: 0.2) {
      self.internetBottomConstraint.constant = -50
      self.view.layoutIfNeeded()
    }
  }

  @objc
  func reachable() {
    // to show the connected view only after the internet was disconnected
    guard disconnected else { return }
    disconnected = false
    UIView.animate(withDuration: 0.2) {
      self.internetBottomConstraint.constant = 0
      self.view.layoutIfNeeded()
    }
  }

  @objc
  func notReachable() {
    disconnected = true
    UIView.animate(
      withDuration: 0.2,
      animations: {
      self.noInternetBottomConstraint.constant = 0
      self.view.layoutIfNeeded()
      }, completion: { _ in
      UIView.animate(
        withDuration: 0.2,
        delay: 3,
        animations: {
        self.noInternetBottomConstraint.constant = -50
        self.view.layoutIfNeeded()
        }, completion: nil)
      })
  }

  @IBAction
  func didPressRefreshBtn(_ sender: Any) {
    collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    loadData()
    animateConnectedViewDown()
  }
}

// MARK: - UICollectionView Delegate
extension ProductsVC: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let detailsVC = StoryboardScene.Main.productDetailsVC.instantiate()
    detailsVC.product = products[indexPath.row]
    present(detailsVC, animated: true, completion: nil)
  }

  // hide connected view if it wasn't hidden
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    animateConnectedViewDown()
  }
}

// MARK: - UICollectionView DataSource
extension ProductsVC: UICollectionViewDataSource {
  // swiftlint:disable next line_length
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    return CGSize(width: collectionView.frame.width, height: 20)
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return products.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as? ProductCell
      else {
      return UICollectionViewCell()
    }
    cell.setupViews(withProduct: products[indexPath.row])
    return cell
  }
}

extension ProductsVC: PinterestLayoutDelegate {
  // 1. Returns the photo height
  func collectionView(_ collectionView: UICollectionView, sizeForPhotoAtIndexPath indexPath: IndexPath) -> CGSize {
    return products[indexPath.row].image.imageSize
  }

}
