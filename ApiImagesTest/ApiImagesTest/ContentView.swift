import SwiftUI

// Esses dois modelos podem estar em arquivos separados
struct RestaurantCategoryJsonListModel: Hashable, Codable {
    let categories: [RestaurantCategoryModel]
}

// Hashable => Permite fazer um for loop dessa scruct, cada objeto ganha um índice, por baixo dos panos.
// Codable => A struct é um "mapa" para um objeto vindo do JSON
struct RestaurantCategoryModel: Hashable, Codable {
    let id: Int
    let name: String
    let thumb_img: String
}

// Esses view model deveria estar em um arquivo separado
class CategoryViewModel: ObservableObject {
    
    // Uma variável published atualiza a UI sempre que tiver alguma modificação.
    // @Published = Toda fez que algum objeto for instanciado em uma thread ou for atualizado pela API, a UI se atualiza.
    @Published var categories: [RestaurantCategoryModel] = []
    
    func fetchDataFromApi() {
        
        // Convertendo a STRING em uma URL
        guard let url = URL(string: "http://137.184.185.55/api/v1/restaurant_category") else {
            return
        }
        
        // Iniciando o request na API
        // weak self => evita a memory leak, apenas atualiza uma lista já existente a invés de criar outra do zero.
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            
            // Verificando se o payload existe (a response retornada da api) e se não existem erros
            guard let data = data, error == nil else {
                return
            }
            
            do {
                //JSONDecoder - Converte a lista de JSONs para uma lista de objetos (model)
                let categoriesJson = try JSONDecoder().decode(RestaurantCategoryJsonListModel.self, from: data)
                
                //Todo objeto @published deve estar na main queue, já que é atualizado pela UI.
                DispatchQueue.main.async {
                    self?.categories = categoriesJson.categories
                }
            }
            catch{
                print(error)
            }
        }
        
        // Fecha a thread da task quando finalizar a transferência dos dados.
        task.resume()
    }
}

// View personalizada que carrega as imagens da URL.
struct URLImage: View {
    let urlString: String
    
    @State var data: Data?
    
    var body: some View {
        if let data = data, let uiimage = UIImage(data: data) {
            Image(uiImage: uiimage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 130, height: 70)
                .background(Color.gray)
        } else {
            Image(systemName: "video")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 70)
                .background(Color.gray)
                .onAppear {
                    fetchImageData()
                }
        }
    }
    
    private func fetchImageData() {
        guard let url = URL(string: urlString) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            self.data = data
        }
        
        task.resume()
    }
}

struct ContentView: View {
    
    //@StateObject => Mantem o estado durante as atualizações de UI. O objeto se mantem o mesmo, independente das atualizações de UI.
    @StateObject var categoriesViewModel = CategoryViewModel()
    var body: some View {
        NavigationView {
            List{
                // Loop para criar cada item da lista.
                ForEach(categoriesViewModel.categories, id: \.self) { category in
                    HStack {
                        URLImage(urlString: category.thumb_img)
                        
                        Text(category.name)
                    }
                    . padding(3)
                }
            }
            .navigationTitle("Categorias")
            .onAppear{
                categoriesViewModel.fetchDataFromApi()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
