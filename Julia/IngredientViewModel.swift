//
//  IngredientViewModel.swift
//  Julia
//
//  Created by Robin Willis on 7/3/24.
//



import Combine

class IngredientViewModel : ObservableObject {
    // var modelContext: ModelContext
    var ingredients = [MockIngredient]()
    
    //init(modelContext: ModelContext) {
        //self.modelContext = modelContext
       // fetchIngredients()
    //}
    
//    func fetchIngredients() {
//        do {
//            let descriptor = FetchDescriptor<Ingredient>(sortBy: [SortDescriptor(\.title)])
//            ingredients = try modelContext.fetch(descriptor)
//        } catch {
//            print("Fetch Ingredients Failed")
//        }
//    }
    
    //@Published var ingredients: [Ingredient] = []
    //@Published var groceries: [Ingredient] = []
    
    func moveToGroceries(ingredient: Ingredient) {
//        if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
//            let movedIngredient = ingredients.remove(at: index)
//            groceries.append(movedIngredient)
//        }
    }

    func moveToIngredients(grocery: Ingredient) {
//        if let index = groceries.firstIndex(where: { $0.id == grocery.id }) {
//            let movedGrocery = groceries.remove(at: index)
//            ingredients.append(movedGrocery)
//        }
    }
    
}

extension IngredientViewModel{
   convenience init(forPreview: Bool = true) {
      self.init()
      //Hard code your mock data for the preview here
      self.ingredients = mockIngredients
      // self.groceries = mockIngredients
   }
}

