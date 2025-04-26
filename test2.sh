#chmod +x test
#./test
#!/bin/bash

# ==========================================================
#            SCRABBLE - Programmation Système
#            Cours de Madame KHADOUJA ZELLAMA
#            William Miserolle TD6
# ==========================================================


alphabet=("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z")

charger_sac(){
    declare -gA points  #-gA , g pour global donc accessible dans tout le code et A pour un tableau associatif
    declare -gA quantite

    while IFS=',' read -r lettre valeur nombre; 
    do 
        val=$(echo "$valeur" | cut -d. -f1)         #on utilise cut pour transformer le float en int car en effet on avait un probleme dans la fonction est_dispo condition erreur de type quand -gt
        nb=$(echo "$nombre" | cut -d. -f1)

        points[$lettre]=$val
        quantite[$lettre]=$nb

    done <$1 

    
    echo "[OK] Sac chargé avec ${#quantite[@]} lettres différentes."
}

charger_sac2() {
    declare -gA points
    declare -gA quantite

    total_lignes=$(wc -l < "$1") # compte le nombre de lignes dans le fichier
    current_ligne=0

    echo -e "\n\e[1;36mChargement du sac de lettres...\e[0m"
    echo -n "[                    ] 0%"

    while IFS=',' read -r lettre valeur nombre; do
        val=$(echo "$valeur" | cut -d. -f1)
        nb=$(echo "$nombre" | cut -d. -f1)

        points[$lettre]=$val
        quantite[$lettre]=$nb

        ((current_ligne++))

        # mise à jour de la barre tous les 1 ou 2 lettres
        if (( current_ligne % 1 == 0 )); then
            percent=$(( current_ligne * 100 / total_lignes ))
            filled=$(( percent / 5 )) # 20 caractères en tout pour la barre

            bar="["
            for ((i=0; i<filled; i++)); do
                bar+="█"
            done
            for ((i=filled; i<20; i++)); do
                bar+=" "
            done
            bar+="]"

            echo -ne "\\r${bar} ${percent}%"
        fi

    done < "$1"

    echo -e "\n\n\e[1;32m[OK] Sac chargé avec ${#quantite[@]} lettres différentes.\e[0m"
}



#POUR DES TESTS
afficher_sac(){
    for lettre in ${!points[@]}
    do
        echo "$lettre vaut ${points[$lettre]} il en reste ${quantite[$lettre]}"
    done
}


est_disponible() {
    lettre=$1
    nombre_dispo=${quantite[$lettre]:-0}

    if [ "$nombre_dispo" -gt 0 ]; 
    then
        return 0
    else
        return 1
    fi
}
#est_disponible z

piocher_lettres() {
    nb=$1

    for ((i=0; i<nb; i++)); 
    do
        while true; #tant que la lettre est pas dispo on reessaie
        do
            choisi=$((RANDOM % 26)) #entre 0 et 25

            lettre_choisie=${alphabet[$choisi]} #on recup la lettre

            #la on va verif sur la lettre est disponible
            if est_disponible "$lettre_choisie"; 
            then
                ((quantite[$lettre_choisie]-=1)) #on l'enleve du sac

                porte_lettres+=("$lettre_choisie") #on l'ajoute au porte lettre

                break
            fi

        done
    done
    return 0
}

compter_points_mot() {
    local mot=$1
    local score=0

    for ((i=0; i<${#mot}; i++)); 
    do
        lettre=${mot:$i:1} #lettre par lettre

        val=${points[$lettre]:-0} #la val de la lettre correspondante grâce au tableau associatif

        ((score+=val))
    done

    echo "$score"
    return 0
}
#compter_points_mot test


#1 si mot dans dico 0 sinon
verif_mot_dico(){
    verif=0
    while IFS= read ligne ;
    do 
        l_dico=$(echo "$ligne" | tr -d '\r') #formater sans le retour à la ligne avec -d : delete et \r les retours à la ligne

        
        if [[ "$1" == "$l_dico" ]];
        then
            verif=1
            break
        fi
        
    done<$2

    echo $verif

} 

#bcp plus efficace grâce a grep que ce que j'avais fait avant en mode "brute_force"
verif_mot_dico2() {
    grep -Fxq "$1" "$2"
    return $?
}

est_dans_porte_lettres() {
    mot=$1
    declare -A compteur_lettres_mot
    declare -A compteur_porte

    #cpt dans le mot
    for ((i=0; i<${#mot}; i++)); 
    do
        lettre=${mot:$i:1}
        ((compteur_lettres_mot[$lettre]++))

    done

    #cpt combien il y a chaque lettre dans le porte lettre    
    for lettre in "${porte_lettres[@]}"; 
    do
        ((compteur_porte[$lettre]+=1))

    done

    #verif si on a les mêmes lettres
    for lettre in "${!compteur_lettres_mot[@]}"; 
    do
        #echo $lettre

        if [[ -z "${compteur_porte[$lettre]}" || ${compteur_lettres_mot[$lettre]} -gt ${compteur_porte[$lettre]} ]]; #si lettre pas dans porte lettre ou pas en nb suffisant
        then
            return 1
        fi

    done

    return 0
}
#est_dans_porte_lettres ski




demander_mot() {
    mot=""
    while true;
    do
        read -rp "Ecrit un mot avec tes lettres : " mot
        if [ ${#mot} -le 7 ]; #verif si il est bien de moins de 7 cara
        then
            echo "$mot"
            return 0
        else
            echo "Le mot est trop long !"
        fi
    done
}







supprimer_lettre() {
    suppr=$1
    temp=()

    #on ajotue a la liste temp si ce n'est pas la lettre a suppr
    for lettre in "${porte_lettres[@]}"; 
    do
        if [ "$lettre" != "$suppr" ]; 
        then
            temp+=("$lettre") #on ajoute a temp si c'est pas la lettre à suppr

        fi
    done

    porte_lettres=("${temp[@]}") #on met a jour porte lettre
    return 0
}

#porte_lettres=("s" "k" "i" "z")
#echo ${porte_lettres[@]}
#supprimer_lettre s
#echo "nv port lettre :  ${porte_lettres[@]}"


untour() {
    echo -e "\e[1;35mTon porte-lettres :\e[0m"
    for lettre in "${porte_lettres[@]}"
    do
        echo -ne "[\e[1;34m$lettre\e[0m] "
    done
    echo -e "\n"

    #echo "Ton porte lettre est : ${porte_lettres[*]}"

    #demande au joueur s'il peut faire un mot
    choix=""
    while [[ "$choix" != "o" && "$choix" != "n" ]]; #tant que c pas o ou n
    do
        read -rp "Peux tu faire un mot ? (o/n) : " choix
    done





    if [[ "$choix" == "o" ]]; 
    then

        mot_joueur=$(demander_mot)

        #VERIF LE MOT EST COMPOSABLE
        if est_dans_porte_lettres "$mot_joueur"; 
        then

            #VERIF SI LE MOT DANS LE DICO
            if verif_mot_dico2 "$mot_joueur" "Dictionnaire.txt"; 
            then
            
                score_mot=$(compter_points_mot "$mot_joueur")
                #echo "ton mot vaut $score_mot"

                ((score_total+=score_mot)) #on met a jour le score du joueur
                
                echo "Bravo ! tu a gagné $score_mot points avec ton mot $mot_joueur !"

                #on enleve du porte lettre les lettres jouées
                for ((i=0; i<${#mot_joueur}; i++)); 
                do
                    lettre=${mot_joueur:$i:1}
                    supprimer_lettre "$lettre"
                done

                #On va remplir le porte lettre pour en avoir 7               
                nb_manquant=$((7 - ${#porte_lettres[@]}))
                piocher_lettres "$nb_manquant"

            else
                echo -e "\e[1;31m mot pas dans le dico : 0 points :(\e[0m"
                echo ""
                porte_lettres=()
                piocher_lettres 7
            fi

        else
            echo -e "\e[1;31m Tu n'as pas les lettres nécessaires\e[0m"
            porte_lettres=()
            piocher_lettres 7
        fi

    else
        echo "Pas grave on va repiocher des lettres"
        porte_lettres=()
        piocher_lettres 7
    fi

    return 0
}

jeu() {
    charger_sac2 Lettres.txt
    score_total=0

    porte_lettres=()
    piocher_lettres 7

    for ((tour=1; tour<=3; tour++)); 
    do
        echo ""
        echo "====== TOUR $tour ======"
        untour
        echo "Score actuel : $score_total"
    done
    echo ""
    echo "===== FIN DE LA PARTIE ====="
    echo "Score final : $score_total"
}

menu_accueil() {
    clear
    echo -e "\e[1;36m"
    echo " ___   ___  ____    __    ____  ____  __    ____ "
    echo "/ __) / __)(  _ \  /__\  (  _ \(  _ \(  )  ( ___)"
    echo "\__ \( (__  )   / /(__)\  ) _ < ) _ < )(__  )__)"
    echo "(___/ \___)(_)\_)(__)(__)(____/(____/(____)(____)"
    echo ""
    echo -e "         \e[1;33m"
    echo "---------------------------------------------------------"
    echo "          SCRABBLE SOLITAIRE - PROGRAMMATION SYSTEME"
    echo "          Cours de Mme Zellama | TD6 - William Miserolle"
    echo "---------------------------------------------------------"
    echo -e "\e[1;36m"
    echo -e "\e[0m"
    echo ""
    echo "le sac peut prendre un peu de temps à charger patience :) "
    echo "Appuie sur Entrer pour commencer..."
    read -r
}



menu_accueil

jeu



