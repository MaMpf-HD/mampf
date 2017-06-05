# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


denis = Teacher.create(name: 'Denis Vogel')
malte = Teacher.create(name: 'Malte Witte')
algebra2 = Course.create(title: 'Algebra 2')
la2 = Course.create(title: 'Lineare Algebra 2')
a2ss16 = Lecture.create(term: 'SS 2016', course: algebra2, teacher: denis)
a2ss17 = Lecture.create(term: 'SS 2017', course: algebra2, teacher: malte)
la2ss17 = Lecture.create(term: 'SS 2017', course: la2, teacher: denis)
tensor_product = Tag.create(title: 'Tensorprodukt von Moduln')
jordan_normal_form = Tag.create(title: 'Jordansche Normalform')
abelian_categories = Tag.create(title: 'Abelsche Kategorien')
la2.contents.create(tag: tensor_product)
la2.contents.create(tag: jordan_normal_form)
algebra2.contents.create(tag: tensor_product)
algebra2.contents.create(tag: abelian_categories)
a2ss17.disabled_contents.create(tag: tensor_product)
