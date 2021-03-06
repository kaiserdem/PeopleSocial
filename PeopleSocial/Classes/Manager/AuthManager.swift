//
//  AuthManager.swift
//  PeopleSocial
//
//  Created by Kaiserdem on 07.01.2019.
//  Copyright © 2019 Kaiserdem. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class AuthManager: FirebaseManager {  // менеджер регистрации
  
  var currentUser: User? // текущий пользователь
  static let shared = AuthManager()
  private let auth = Auth.auth() // переменная авторизации
  
  // войти в случае необходимости, опициональный блок комплетишион
  func singInIfNeeded(completion: ItemClosure<FirebaseResult>? = nil) {
    
    let credentials = SecureStorageManager.shared.loadEmailAndPassword() // полномочия на загрузку
    guard let email = credentials.email, let password = credentials.password else {
      return
    }
    singIn(with: email, and: password, completion: completion ?? {_ in})
  }
  // функция для авторизации
  func singIn(with email: String?, and password: String?, completion: @escaping ItemClosure<FirebaseResult>) {
    
    guard let email = email, let password = password else { // проверка, вернуть если не существует
      completion(FirebaseResult.error("Something wrong with email or password. Please try again"))
      return
    }
  
    auth.signIn(withEmail: email, password: password) { (result, error) in
      if let error = error {
        completion(FirebaseResult.error(error.localizedDescription))// не удалось
        return
      }
      guard let user = result?.user else {
        completion(FirebaseResult.error("User not exist")) // не существует

        return
      }
      self.currentUser = user
      completion(FirebaseResult.success) // успешно
    }
  }
  
  // загружает модель данных
  func register(with model: RegisterModel, completion: @escaping ResultHandler<Void>) {
    // создаем модель нового пользователя ветки пользователя
    guard model.isFiled else {
      completion(.failure(CustomErrors.unknownError))
      return
    }
    guard let email = model.email, let password = model.password else {
      completion(.failure(CustomErrors.unknownError))
      return
    }
    guard Validators.isSimlpeEmail(email) else {
      completion(.failure(CustomErrors.invalidEmail))
      return
    }
    
    let id = model.userId // берем афди пользователя
    auth.createUser(withEmail: email, password: password) { result, error in
      if let error = error {
        completion(.failure(error))
      return
      }
      
      guard let res = result else {
        completion(.failure(CustomErrors.unknownError))
        return
      }
      self.currentUser = res.user
      
      var dict = model.dict
      dict["id"] = id
      self.usersRef.child(res.user.uid).setValue(dict, withCompletionBlock: { (error, reference) in
        self.addAvatarUrlIfNeded(for: model, user: res.user)
        completion(.success(()))
      })
    }
  }             // добавляем ссылку на фото в бд
  func addAvatarUrlIfNeded(for model: RegisterModel, user: User) {
    StorageManager.shared.loadAvatarUrl(for: model) { (url) in // загружаем url
      guard let url = url else { // проверяем на нил
        return
      }// нашли юзера по child, создаем новую ветку, записываем в базу
      self.usersRef.child(user.uid).child("avatarUrl").setValue(url.absoluteString)
    }
  }
}


