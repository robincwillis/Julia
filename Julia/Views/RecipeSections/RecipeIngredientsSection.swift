//
//  RecipeIngredientsSection.swift
//  Julia
//
//  Created by Robin Willis on 3/2/25.
//

import SwiftUI
import SwiftData

// Extension to allow for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, 
                               byRoundingCorners: corners, 
                               cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct RecipeIngredientsSection: View {
    let recipe: Recipe
    let isEditing: Bool
    @Binding var editedIngredients: [Ingredient]
    @Binding var editedSections: [IngredientSection]
    @Binding var selectedIngredient: Ingredient?
    @Binding var showingIngredientEditor: Bool
    @FocusState var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Ingredients")
                    .font(.headline)
                    .padding(.bottom, 6)
                
                if isEditing {
                    Spacer()
                    Button(action: {
                        addNewSection()
                    }) {
                        Label("Add Section", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                    .background(Color(red: 0.85, green: 0.92, blue: 1.0))
                }
            }
            
            if !isEditing {
                // Ingredients display mode
                if recipe.sections.isEmpty {
                    ForEach(recipe.ingredients, id: \.self) { ingredient in
                        IngredientRow(ingredient: ingredient, padding: 3)
                    }
                } else {
                    ForEach(recipe.sections.sorted(by: { $0.position < $1.position }), id: \.self) { section in
                        VStack(alignment: .leading) {
                            Text(section.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                            
                            ForEach(section.ingredients, id: \.self) { ingredient in
                                IngredientRow(ingredient: ingredient, padding: 3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                // Ingredients edit mode
                // Display debug info
                Text("Editing: \(editedIngredients.count) ingredients, \(editedSections.count) sections")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                if editedSections.isEmpty {
                    // Simple ingredient list (no sections)
                    if editedIngredients.isEmpty {
                        // No ingredients yet
                        VStack {
                            Text("No ingredients added yet")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    } else {
                        // Show ingredients list using List with direct binding
                        List($editedIngredients, id: \.id, editActions: [.delete, .move]) { $ingredient in
                            HStack {
                                IngredientRow(ingredient: ingredient, padding: 3)
                                
                                Spacer()
                                
                                Button(action: {
                                    editIngredient(ingredient)
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                        .frame(minHeight: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        addNewIngredient()
                    }) {
                        Label("Add Ingredient", systemImage: "plus")
                            .foregroundColor(.blue)
                            .background(Color(red: 0.85, green: 0.92, blue: 1.0))
                    }
                    .padding(.vertical, 6)
                } else {
                    // Sections with ingredients
                    List {
                        ForEach($editedSections, id: \.id, editActions: [.move, .delete]) { $section in
                            Section(header: 
                                TextField("Section name", text: $section.name)
                                    .font(.headline)
                                    .listRowBackground(Color(.systemGray5))
                            ) {
                                if section.ingredients.isEmpty {
                                    Text("No ingredients in this section")
                                        .foregroundColor(.secondary)
                                        .italic()
                                } else {
                                    ForEach($section.ingredients, id: \.id, editActions: [.move, .delete]) { $ingredient in
                                        HStack {
                                            IngredientRow(ingredient: ingredient, padding: 3)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                editIngredient(ingredient)
                                            }) {
                                                Image(systemName: "pencil")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                                
                                Button {
                                    addNewIngredientToSection(editedSections.firstIndex(where: { $0.id == section.id }) ?? 0)
                                } label: {
                                    Label("Add Ingredient", systemImage: "plus.circle")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .frame(minHeight: 300)
                    
                    Button(action: {
                        addNewSection()
                    }) {
                        Label("Add Section", systemImage: "plus")
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        Divider()
    }
    
    // MARK: - Ingredient Functions
    
    private func addNewIngredient() {
        let newIngredient = Ingredient(name: "New Ingredient", location: .recipe)
        editedIngredients.append(newIngredient)
        // Open edit screen for the new ingredient
        editIngredient(newIngredient)
    }
    
    private func addNewIngredientToSection(_ sectionIndex: Int) {
        let newIngredient = Ingredient(name: "New Ingredient", location: .recipe)
        editedSections[sectionIndex].ingredients.append(newIngredient)
        // Open edit screen for the new ingredient
        editIngredient(newIngredient)
    }
    
    private func deleteIngredient(at index: Int) {
        editedIngredients.remove(at: index)
    }
    
    private func deleteIngredientFromSection(at ingredientIndex: Int, in sectionIndex: Int) {
        // This function is now mostly handled by the ForEach editActions
        // It's kept for compatibility with any manual deletion needs
        editedSections[sectionIndex].ingredients.remove(at: ingredientIndex)
    }
    
    private func editIngredient(_ ingredient: Ingredient) {
        selectedIngredient = ingredient
        showingIngredientEditor = true
    }
    
    // MARK: - Section Functions
    
    private func addNewSection() {
        let newSection = IngredientSection(name: "New Section", position: editedSections.count)
        editedSections.append(newSection)
    }
    
    private func deleteSection(at index: Int) {
        // Move ingredients from this section to unsectioned if needed
        let sectionIngredients = editedSections[index].ingredients
        editedIngredients.append(contentsOf: sectionIngredients)
        
        editedSections.remove(at: index)
        
        // Update remaining section positions
        for i in index..<editedSections.count {
            editedSections[i].position = i
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var ingredients: [Ingredient] = [
            Ingredient(name: "Flour", location: .recipe, unit: "cup"),
            Ingredient(name: "Sugar", location: .recipe, unit: "cup")
        ]
        @State private var sections: [IngredientSection] = []
        @State private var selectedIngredient: Ingredient?
        @State private var showEditor = false
        @FocusState private var focused: Bool
        
        var body: some View {
            RecipeIngredientsSection(
                recipe: Recipe(
                    title: "Sample Recipe",
                    summary: "A delicious sample recipe",
                    ingredients: ingredients,
                    instructions: []
                ),
                isEditing: true,
                editedIngredients: $ingredients,
                editedSections: $sections,
                selectedIngredient: $selectedIngredient,
                showingIngredientEditor: $showEditor,
                isTextFieldFocused: _focused
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}
