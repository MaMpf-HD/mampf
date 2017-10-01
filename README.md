# README

This is supposed to become an API for the MaMpf project.
As of now, only the models and some class methods have been implemented, together with a rake task that imports real world data from csv files. Just play around with it to get a feeling...

* Ruby version: 2.4.0
* Rails Version: 5.1.2

* Database initialization:

    `rails setup:import_data`

  This imports a lot of data from the .csv files in the db/csv folder

* Test suite: rspec

## Examples

For the brevity of presentation, we pick out only very few data.

```
    jnf = Tag.find_by(title: 'Jordansche Normalform')
    jnf.courses.pluck('title')
    # => ["Lineare Algebra 2"]
    jnf.media.pluck(:title)
    #  => ["KaViaR.SS17.LA2.E21", "SeSAM.SS17.LA2.E10", "KeKs.V2516", "KeKs.V2517", "KeKs.V2522", "KeKs.V2524", "KeKs.SS17.LA2.Q09"]
    jnf.media.last.external_reference_link    #=> "https://keks.mathi.uni-heidelberg.de/hitme#hide-options#hide-categories#question=2516,2517,2522,2524"
    jnf.lessons.pluck(:date)
    # => [Tue, 04 Jul 2017]
    jnf.related_tags.pluck(:title)
    # => ["Charakterisierungen von Diagonalisierbarkeit", "Elementarteilersatz für Matrizen über Euklidischen
    # Ringen", "Weierstrass-Normalform", "Jordanmatrix"]
    jnf.related_tags.first.media.pluck(:title)
    # => ["KaViaR.SS17.LA2.E01", "KaViaR.SS17.LA2.E02", "KaViaR.SS17.LA2.E03", "KaViaR.SS17.LA2.E04",
    # "RestE.SS17.LA2.AltQuiz.E01"]
    jnf.tags_with_given_distance(2).pluck(:title)
    # => ["Eigenwert", "charakteristisches Polynom eines Endomorphismus", "algebraische Vielfachheit eines
    # Eigenwerts", "Minimalpolynom eines Endomorphismus", "Spektralsatz für selbstadjungierte Endomorphismen",
    # "Spektralsatz für normale Endomorphismen", "Euklidischer Ring", "Gauß-Diagonalisierung von Matrizen über
    # Euklidischen Ringen", "Äquivalenz und Ähnlichkeit von Matrizen über Ringen", "Fittingideale", "Fittings
    # Lemma", "Invarianten- und Determinantenteiler einer Matrix", "Invariantenteilersatz", "Begleitmatrix",
    # "Frobenius-Normalform"]
```
